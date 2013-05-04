//  Created by JGroup(kimbobv22@gmail.com)

#import "CMMStageTMX.h"
#import "CMMStringUtil.h"

@implementation CMMStageTMX{
	float _lastScale,_firstRotation;
	CGPoint _lastPoint;
	
	CMMGestureDispatcher *_gestureDispatcher;
}
@synthesize tilemap,groundTMXLayers,tilemapBuiltup,callback_tileBuiltup,filter_isSingleTile;

+(id)stageWithStageDef:(CMMStageDef)stageDef_ tmxFileName:(NSString *)tmxFileName_ isInDocument:(BOOL)isInDocument_{
	return [[[self alloc] initWithStageDef:stageDef_ tmxFileName:tmxFileName_ isInDocument:isInDocument_] autorelease];
}

-(id)initWithStageDef:(CMMStageDef)stageDef_{
	//do not use for init
	[self release];
	return nil;
}
-(id)initWithStageDef:(CMMStageDef)stageDef_ tmxFileName:(NSString *)tmxFileName_ isInDocument:(BOOL)isInDocument_{
	tilemap = [CCTMXTiledMap tiledMapWithTMXFile:[CMMStringUtil stringPathWithFileName:tmxFileName_ isInDocument:isInDocument_]];
	
	//only support Orthogonal orientation
	if([tilemap mapOrientation] != CCTMXOrientationOrtho){
		[self release];
		return nil;
	}

	stageDef_.worldSize = [tilemap contentSize];
	
	if(!(self = [super initWithStageDef:stageDef_])) return self;
	[self addChild:tilemap z:1];
	
	groundTMXLayers = [[CCArray alloc] init];
	tilemapBuiltup = NO;
	
	b2MaskTile = CMMb2ContactMaskMake(0x3009,-1,-1,1);
	


    _gestureDispatcher = [[CMMGestureDispatcher alloc] initWithDelegate:self];

    //long press
    [_gestureDispatcher initializeLongPressRecognizer];
    [[_gestureDispatcher longPressRecognizer] setMinimumPressDuration:3.0f];

    //pinch, rotation, pan
    [_gestureDispatcher initializePinchRecognizer];
    //[_gestureDispatcher initializeRotataionRecognizer];
    [_gestureDispatcher initializePanRecognizer];
    [[_gestureDispatcher panRecognizer] setMinimumNumberOfTouches:1];

    return self;
}

-(void)gestureDispatcher:(CMMGestureDispatcher *)gestureDispatcher_ whenLongPressEvent:(UIPinchGestureRecognizer *)gestureRecognizer_{
	CCLOG(@"long press gesture fired : %d",[gestureRecognizer_ state]);
}
-(void)gestureDispatcher:(CMMGestureDispatcher *)gestureDispatcher_ whenPinchEvent:(UIPinchGestureRecognizer *)gestureRecognizer_{
	switch([gestureRecognizer_ state]){
		case UIGestureRecognizerStateBegan:{
			_lastScale = 1.0f;
			break;
		}
		case UIGestureRecognizerStateChanged:{
			float curScale_ = [tilemap scale];
			[tilemap setScale:curScale_ - (curScale_ * (_lastScale - [gestureRecognizer_ scale]))];
			_lastScale = [gestureRecognizer_ scale];
			break;
		}
		default: break;
	}
}
-(void)gestureDispatcher:(CMMGestureDispatcher *)gestureDispatcher_ whenRotationEvent:(UIRotationGestureRecognizer *)gestureRecognizer_{
	switch([gestureRecognizer_ state]){
		case UIGestureRecognizerStateBegan:{
			_firstRotation = [tilemap rotation];
			break;
		}
		case UIGestureRecognizerStateChanged:{
			float targetRotation_ = [gestureRecognizer_ rotation];
			[tilemap setRotation:_firstRotation + CC_RADIANS_TO_DEGREES(targetRotation_)];
			break;
		}
		default: break;
	}
}
-(void)gestureDispatcher:(CMMGestureDispatcher *)gestureDispatcher_ whenPanEvent:(UIPanGestureRecognizer *)gestureRecognizer_{
	switch([gestureRecognizer_ state]){
		case UIGestureRecognizerStateBegan:{
			_lastPoint = CGPointZero;
			break;
		}
		case UIGestureRecognizerStateChanged:{
			CGPoint targetPoint_ = [gestureRecognizer_ translationInView:[gestureRecognizer_ view]];
			CGPoint diffPoint_ = ccpSub(targetPoint_, _lastPoint);
			[tilemap setPosition:ccpAdd([tilemap position], ccp(diffPoint_.x,-diffPoint_.y))];
			
			_lastPoint = targetPoint_;
			
			break;
		}
		default: break;
	}
}

-(void)cleanup{
	[_gestureDispatcher setDelegate:nil];
    [self setCallback_tileBuiltup:nil];
	[self setFilter_isSingleTile:nil];
	[super cleanup];
}
-(void)dealloc{
    [callback_tileBuiltup release];
	[filter_isSingleTile release];
	[groundTMXLayers release];
	[_gestureDispatcher release];
	[super dealloc];
}



-(void)setWorldPoint:(CGPoint)worldPoint_{
	[super setWorldPoint:worldPoint_];
	[tilemap setPosition:[world position]];
}

-(void)setWorldScale:(float)worldScale_{
	[super setWorldScale:worldScale_];
	[tilemap setScale:worldScale_];
}

-(void)step:(ccTime)dt_{
	if(!tilemapBuiltup) return;
	[super step:dt_];
}



@end

@implementation CMMStageTMX(Tilemap)

-(void)addGroundTMXLayerAtLayerName:(NSString *)tmxLayerName_{
	if(tilemapBuiltup) return;
	
	CCTMXLayer *tmxLayer_ = [tilemap layerNamed:tmxLayerName_];
	if([groundTMXLayers indexOfObject:tmxLayer_] != NSNotFound) return;
	[groundTMXLayers addObject:tmxLayer_];
}
-(void)removeGroundTMXLayerAtLayerName:(NSString *)tmxLayerName_{
	if(tilemapBuiltup) return;
	
	CCTMXLayer *tmxLayer_ = [tilemap layerNamed:tmxLayerName_];
	if([groundTMXLayers indexOfObject:tmxLayer_] == NSNotFound) return;
	[groundTMXLayers removeObject:groundTMXLayers];
}

-(void)buildupTilemapWithBlock:(void(^)())block_{
	if(tilemapBuiltup){
		CCLOG(@"tilemap is already been built up!");
		return;
	}
	
	cmmFunc_callBackQueue(^{
		b2Body *worldBody_ = world.worldBody;
		ccArray *groundData_ = groundTMXLayers->data;
		int count_ = groundData_->num;
		for(uint index_=0;index_<count_;++index_){
			CCTMXLayer *tmxLayer_ = groundData_->arr[index_];
			
			CGSize tileLayerSize_ = tmxLayer_.layerSize;
			uint totalTileLength_ = (int)tileLayerSize_.width*tileLayerSize_.height;
			b2Vec2 tileSizeUint_ = b2Vec2_PTM_RATIO((tmxLayer_.mapTileSize.width/CC_CONTENT_SCALE_FACTOR())/2.0f, (tmxLayer_.mapTileSize.height/CC_CONTENT_SCALE_FACTOR())/2.0f);
			
			float startXIndex_ = -1;
			float startYIndex_ = -1;
			BOOL doDraw_ = NO;
			
			for(int tileIndex_=0; tileIndex_<totalTileLength_;++tileIndex_){
				float curYIndex_ = cmmFuncCMMStageTMX_tileYIndex(tileIndex_,tileLayerSize_.width);
				float curXIndex_ = cmmFuncCMMStageTMX_tileXIndex(tileIndex_,tileLayerSize_.width,curYIndex_);
				
				CCSprite *tile_ = [tmxLayer_ tileAt:ccp(curXIndex_,(tileLayerSize_.height-1.0f)-curYIndex_)];
				//		u_int32_t tile_ = [tmxLayer_ tileGIDAt:ccp(curXIndex_,(tileLayerSize_.height-1.0f)-curYIndex_)];
				if(tile_){
					if(startXIndex_<0){
						startXIndex_ = curXIndex_;
						startYIndex_ = curYIndex_;
						doDraw_ = NO;
					}
					
					float nextYIndex_ = cmmFuncCMMStageTMX_tileYIndex(tileIndex_+1.0f,tileLayerSize_.width);
					if(nextYIndex_ != curYIndex_){
						curXIndex_++; //issue
						doDraw_ = YES;
					}else doDraw_ = NO;
					
					if(!doDraw_ && filter_isSingleTile){
						if(filter_isSingleTile(tmxLayer_,tile_,curXIndex_,curYIndex_)){
							curXIndex_++;
							doDraw_ = YES;
						}
					}
					
				}else if(startXIndex_>=0) doDraw_ = YES;
				
				if(doDraw_){
					b2Vec2 tileSize_ = b2Vec2(tileSizeUint_.x*(curXIndex_-startXIndex_),tileSizeUint_.y);
					b2Vec2 tilePoint_ = b2Vec2((tileSizeUint_.x*2.0f*startXIndex_)+tileSize_.x,(tileSizeUint_.y*2.0f*startYIndex_)+tileSize_.y);
					
					b2PolygonShape blockShape_;
					blockShape_.SetAsBox(tileSize_.x, tileSize_.y, tilePoint_, 0);
					
					b2FixtureDef fixtureDef_;
					fixtureDef_.friction = [spec friction];
					fixtureDef_.restitution = [spec restitution];
					fixtureDef_.density = [spec density];
					fixtureDef_.shape = &blockShape_;
					b2Fixture *tileFixture_ = worldBody_->CreateFixture(&fixtureDef_);
					tileFixture_->SetUserData(&b2MaskTile);
					
					if(callback_tileBuiltup){
						callback_tileBuiltup(tmxLayer_,startXIndex_,curXIndex_,startYIndex_,tileFixture_);
					}
					
					doDraw_ = NO;
					startXIndex_ = startYIndex_ = -1;
				}
			}
		}
		tilemapBuiltup = YES;
		if(block_){
			cmmFunc_callMainQueue(block_);
		}
	});
}
-(void)buildupTilemap{
	[self buildupTilemapWithBlock:nil];
}

@end

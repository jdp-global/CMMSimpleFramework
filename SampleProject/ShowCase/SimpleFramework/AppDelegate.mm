//  Created by JGroup(kimbobv22@gmail.com)

#import "AppDelegate.h"
#import "CommonIntroLayer.h"
#import "CMMScrollViewLayer.h"


@implementation MyViewController

// The available orientations should be defined in the Info.plist file.
// And in iOS 6+ only, you can override it in the Root View controller in the "supportedInterfaceOrientations" method.
// Only valid for iOS 6+. NOT VALID for iOS 4 / 5.
-(NSUInteger)supportedInterfaceOrientations {
	
	// iPhone only
	if( [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone )
		return UIInterfaceOrientationMaskLandscape;
	
	// iPad only
	return UIInterfaceOrientationMaskLandscape;
}

// Supported orientations. Customize it for your own needs
// Only valid on iOS 4 / 5. NOT VALID for iOS 6.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// iPhone only
	if( [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone )
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	
	// iPad only
	// iPhone only
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

// This is needed for iOS4 and iOS5 in order to ensure
// that the 1st scene has the correct dimensions
// This is not needed on iOS6 and could be added to the application:didFinish...
-(void) directorDidReshapeProjection:(CCDirector*)director_{
	if([director_ runningScene] == nil) {
		// Add the first scene to the stack. The director will draw it immediately into the framebuffer. (Animation is started automatically when the view is displayed.)
		// and add the scene to the stack. The director will run it when it automatically when the view is displayed.
		
		//touch configuration
		CCGLView *glView_ = (CCGLView *)[director_ view];
		[glView_ setMultipleTouchEnabled:YES];
		[glView_ setTouchDelegate:[CMMScene sharedScene]];
		
        
		//push scene(only once)
		[director_ pushScene:[CMMScene sharedScene]];
		
        
       /* CGSize s = [[CCDirector sharedDirector] winSize];
        CMMScrollViewLayer *sl = [[CMMScrollViewLayer alloc] initWithColor:ccc4(0,1,0,0) width:s.width height:s.height];
        [[CMMScene sharedScene] pushLayer:sl];*/
        
        
        
       CGSize targetSize_ = [[CCDirector sharedDirector] winSize];
        CMMStageDef stageDef_ = CMMStageDefMake(CGSizeMake(targetSize_.width, targetSize_.height),CGSizeMake(1000, 1000),ccp(0,0));
        
        CMMStageTMX *stage_ = [CMMStageTMX stageWithStageDef:stageDef_ tmxFileName:@"TMX_SAMPLE_000.tmx" isInDocument:NO];
        stage_.touchEnabled = YES;
        [stage_ initializeLightSystem]; // lazy initialization
        
        [stage_ setFilter_isSingleTile:^BOOL(CCTMXLayer *tmxLayer_, CCSprite *tile_, float xIndex_, float yIndex_) {
            return NO;
        }];
        [stage_ setCallback_tileBuiltup:^(CCTMXLayer *tmxLayer_, float fromXIndex_, float toXIndex_, float yIndex_, b2Fixture *tileFixture_) {
            CCLOG(@"tile built up! [ X : %d -> %d , Y: %d ]",(int)fromXIndex_,(int)toXIndex_,(int)yIndex_);
        }];
        
       [[CMMScene sharedScene] pushLayer:stage_];
        
        
		//push layer
		//[[CMMScene sharedScene] pushLayer:[CommonIntroLayer1 node]];
		
		//add default background
		/*CCSprite *defaultBackGround_ = [CCSprite spriteWithFile:@"IMG_CMN_DEFAULT_BACK.png"];
		[defaultBackGround_ setPosition:cmmFunc_positionIPN([CMMScene sharedScene],defaultBackGround_)];
		[[CMMScene sharedScene] setDefaultBackGroundNode:defaultBackGround_];*/
	}
}

@end

@implementation AppController

@synthesize window=window_, navController=navController_, director=director_;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// Create the main window
	window_ = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	// Create an CCGLView with a RGB565 color buffer, and a depth buffer of 0-bits
	CCGLView *glView = [CCGLView viewWithFrame:[window_ bounds]
								   pixelFormat:kEAGLColorFormatRGB565	//kEAGLColorFormatRGBA8
								   depthFormat:0	//GL_DEPTH_COMPONENT24_OES
							preserveBackbuffer:NO
									sharegroup:nil
								 multiSampling:NO
							   numberOfSamples:0];

	director_ = (CCDirectorIOS*) [CCDirector sharedDirector];
	director_.wantsFullScreenLayout = YES;

	// Display FSP and SPF
	[director_ setDisplayStats:YES];

	// set FPS at 60
	[director_ setAnimationInterval:1.0/60];

	// attach the openglView to the director
	[director_ setView:glView];

	// 2D projection
	[director_ setProjection:kCCDirectorProjection2D];
//	[director setProjection:kCCDirectorProjection3D];

	// Enables High Res mode (Retina Display) on iPhone 4 and maintains low res on all other devices
	if( ! [director_ enableRetinaDisplay:YES] )
		CCLOG(@"Retina Display Not supported");

	// Create a Navigation Controller with the Director
	navController_ = [[MyViewController alloc] initWithRootViewController:director_];
	navController_.navigationBarHidden = YES;
	// for rotation and other messages
	[director_ setDelegate:navController_];
	
	// set the Navigation Controller as the root view controller
	[window_ setRootViewController:navController_];
	//[window_ addSubview:navController_.view];

	// make main window visible
	[window_ makeKeyAndVisible];

	// Default texture format for PNG/BMP/TIFF/JPEG/GIF images
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
	// You can change anytime.
	[CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];

	// If the 1st suffix is not found and if fallback is enabled then fallback suffixes are going to searched. If none is found, it will try with the name without suffix.
	// On iPad HD  : "-ipadhd", "-ipad",  "-hd"
	// On iPad     : "-ipad", "-hd"
	// On iPhone HD: "-hd"
	CCFileUtils *sharedFileUtils = [CCFileUtils sharedFileUtils];
	[sharedFileUtils setEnableFallbackSuffixes:NO];				// Default: NO. No fallback suffixes are going to be used
	[sharedFileUtils setiPhoneRetinaDisplaySuffix:@"-hd"];		// Default on iPhone RetinaDisplay is "-hd"
	[sharedFileUtils setiPadSuffix:@"-ipad"];					// Default on iPad is "ipad"
	[sharedFileUtils setiPadRetinaDisplaySuffix:@"-ipadhd"];	// Default on iPad RetinaDisplay is "-ipadhd"
	[[sharedFileUtils suffixesDict] setObject:@"-hd" forKey:kCCFileUtilsiPhone5];

	// Assume that PVR images have premultiplied alpha
	[CCTexture2D PVRImagesHavePremultipliedAlpha:YES];

	return YES;
}

// must put this code on iOS6.
-(NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window{
	return UIInterfaceOrientationMaskAll;
}

// getting a call, pause the game
-(void) applicationWillResignActive:(UIApplication *)application
{
	if( [navController_ visibleViewController] == director_ ){
		[director_ pause];
	}
}

// call got rejected
-(void) applicationDidBecomeActive:(UIApplication *)application
{
	if( [navController_ visibleViewController] == director_ ){
		[director_ resume];
	}
}

-(void) applicationDidEnterBackground:(UIApplication*)application
{
	if( [navController_ visibleViewController] == director_ ){
		[director_ stopAnimation];
	}
}

-(void) applicationWillEnterForeground:(UIApplication*)application
{
	if( [navController_ visibleViewController] == director_ ){
		[director_ startAnimation];
	}
}

// application will be killed
- (void)applicationWillTerminate:(UIApplication *)application
{
	CC_DIRECTOR_END();
}

// purge memory
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	[[CCDirector sharedDirector] purgeCachedData];
}

// next delta time will be zero
-(void) applicationSignificantTimeChange:(UIApplication *)application
{
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

- (void) dealloc
{
	[window_ release];
	[navController_ release];

	[super dealloc];
}
@end

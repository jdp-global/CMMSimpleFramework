//  Created by JGroup(kimbobv22@gmail.com)

#import "CMMHeader.h"

@interface GyroTestLayer : CMMLayer<CMMSceneLoadingProtocol,CMMMenuItemDelegate,CMMMotionDispatcherDelegate>{
	CCLabelTTF *displayLabel;
	CMMStage *stage;
}

-(void)update:(ccTime)dt_;

@end

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVCaptureSession.h>
#import <AVFoundation/AVCaptureOutput.h>
#import <CoreVideo/CVPixelBuffer.h>

@interface ViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate> {
    
}

@property (nonatomic, retain) AVCaptureVideoDataOutput *videoOutput;
@property (weak, nonatomic) IBOutlet UIImageView *captureImage;

@end

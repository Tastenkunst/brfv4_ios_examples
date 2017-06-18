#import "ViewController.h"

#include "brfv4/BRFManager.hpp"
#include "brfv4/image/BRFBitmapData.hpp"

#include "brfv4/ios/DrawingUtils.hpp"

#include "brfv4/utils/BRFv4PointUtils.hpp"
#include "brfv4/utils/BRFv4ExtendedFace.hpp"

#include "brfv4/examples/Basic_Example.hpp"

// +++ basic face detection

//#include "brfv4/examples/face_detection/detect_in_whole_image.hpp"
//#include "brfv4/examples/face_detection/detect_in_center.hpp"
//#include "brfv4/examples/face_detection/detect_smaller_faces.hpp"
//#include "brfv4/examples/face_detection/detect_larger_faces.hpp"

// +++ basic - face tracking +++

#include "brfv4/examples/face_tracking/track_single_face.hpp"
//#include "brfv4/examples/face_tracking/track_multiple_faces.hpp"
//#include "brfv4/examples/face_tracking/candide_overlay.hpp"

// +++ basic - point tracking +++

//#include "brfv4/examples/point_tracking/track_multiple_points.hpp"	// not implemented
//#include "brfv4/examples/point_tracking/track_points_and_face.hpp"	// not implemented

// +++ intermediate - face tracking +++

//#include "brfv4/examples/face_tracking/restrict_to_center.hpp"
//#include "brfv4/examples/face_tracking/extended_face_shape.hpp"
//#include "brfv4/examples/face_tracking/smile_detection.hpp"
//#include "brfv4/examples/face_tracking/yawn_detection.hpp"
//#include "brfv4/examples/face_tracking/png_mask_overlay.hpp"			// not implemented
//#include "brfv4/examples/face_tracking/color_libs.hpp"

// +++ advanced - face tracking +++

//#include "brfv4/examples/face_tracking/blink_detection.hpp"
//#include "brfv4/examples/face_tracking/ThreeJS_example.hpp"			// not implemented
//#include "brfv4/examples/face_tracking/face_texture_overlay.hpp"		// not implemented
//#include "brfv4/examples/face_tracking/face_swap_two_faces.hpp"		// not implemented

// ### camera stuff

static int _imageDataWidth  = 480;	// default: landscape camera 480x640
static int _imageDataHeight = 640;
static size_t _imageBufferBytesPerRow = 1920; // var for context creation

static bool _mirrored = true;
static bool _useFrontCam = true;

static NSString* _defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
static AVCaptureVideoOrientation _defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
static AVCaptureSession *session;
static dispatch_queue_t videoQueue;

// ### example stuff

static brf::BRFCppExample example;

#if (TARGET_OS_SIMULATOR > 0)
static bool _isSimulator = true;
#else
static bool _isSimulator = false;
#endif

// ### implementation

@interface ViewController ()
@end

@implementation ViewController

@synthesize captureImage, videoOutput;

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    brf::trace("resolution: " + brf::to_string(screenBounds.size.width) + " " +
               brf::to_string(screenBounds.size.height));
}

- (void)viewDidAppear:(BOOL)animated {

    // Camera setup
    
    if(!_isSimulator) {
        [self initializeCamera];
    } else {
        _imageBufferBytesPerRow = 1920;
    }

    // Init BRF example. Size should be the set camera resolution.
    
    example.init(_imageDataWidth, _imageDataHeight, brf::ImageDataType::U8_RGBA);
}

// Delegate routine that is called when a camera sample buffer was written.
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    // Create autorelease pool because we are not in the main_queue
    @autoreleasepool {
        
        // Get a CMSampleBuffer's Core Video image buffer for the media data
        // ... lock the base address of the pixel buffer
        CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer, 0);
        
        // Get the pixel buffer width and height
        int width  = (int)CVPixelBufferGetWidth(imageBuffer);
        int height = (int)CVPixelBufferGetHeight(imageBuffer);
        
        if(width != _imageDataWidth || height != _imageDataHeight) {
            
            brf::trace("Error: wrong video input size: width: " + brf::to_string(width) +
                       " height: " + brf::to_string(height));
            brf::trace("... changing videoOrientation ...");
            
            [connection setVideoOrientation: 	_defaultAVCaptureVideoOrientation];
            [connection setVideoMirrored: 		_mirrored];
            
        } else {
        
            // BRF ready?
        
            if(example._initialized) {
        
                // Camera ready?
        
                if(_imageBufferBytesPerRow > 0) {
                    
                    // Get the pixel data from the camera image
                    
                    _imageBufferBytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
                    uint8_t* baseAddress = (uint8_t*) CVPixelBufferGetBaseAddress(imageBuffer);
                    
                    // Create a device-dependent RGB color space
                    // ... create a bitmap graphics context with the sample buffer data
                    
                    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
                    CGContextRef context = CGBitmapContextCreate(
                            baseAddress, _imageDataWidth, _imageDataHeight, 8, _imageBufferBytesPerRow,
                            colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
                    
                    // Set the context for Drawing
                    
                    example._drawing._context = context;
                    
                    // Update example and draw the results into the context
                    
                    example.update(baseAddress);
                    
                    // Create a Quartz image from the pixel data in the bitmap graphics context
                    // ... free up the context and color space
                    // ... create an image object from the Quartz image
                    // ... release stuff
        
                    CGImageRef contextQuartzImage = CGBitmapContextCreateImage(context);
                    UIImage *contextImage = [UIImage imageWithCGImage:contextQuartzImage];
        
                    [captureImage performSelectorOnMainThread:@selector(setImage:) withObject:contextImage waitUntilDone:NO];
                    
                    CGContextRelease(context);
                    CGColorSpaceRelease(colorSpace);
                    CGImageRelease(contextQuartzImage);
                    
                } else {
                    brf::trace("onUpdateCamera: init done, but no camera frame yet.");
                }
            } else {
                brf::trace("onUpdateCamera: initializing");
            }
        }
        
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    example.reset();
}

- (void) initializeCamera {

    session = [[AVCaptureSession alloc] init];
    session.sessionPreset = _defaultAVCaptureSessionPreset;
    
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *frontCamera;
    AVCaptureDevice *backCamera;
    
    for (AVCaptureDevice *device in devices) {
        
        NSLog(@"Device name: %@", [device localizedName]);
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionBack) {
                NSLog(@"Device position : back");
                backCamera = device;
            }
            else {
                NSLog(@"Device position : front");
                frontCamera = device;
            }
        }
    }
    
    if (!_useFrontCam) {
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
        if (!input) {
            NSLog(@"ERROR: trying to open camera: %@", error);
        }
        [session addInput:input];
    }
    
    if (_useFrontCam) {
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
        if (!input) {
            NSLog(@"ERROR: trying to open camera: %@", error);
        }
        [session addInput:input];
    }
    
    // Create a VideoDataOutput and add it to the session
    videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    NSDictionary *rgbOutputSettings =
    [NSDictionary dictionaryWithObject:
     [NSNumber numberWithInt:kCMPixelFormat_32BGRA]
                                forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    [videoOutput setVideoSettings:rgbOutputSettings];
    [videoOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked (as we process the still image)
    
    // Configure your output.
    videoQueue = dispatch_queue_create("myQueue", DISPATCH_QUEUE_SERIAL);
    [videoOutput setSampleBufferDelegate:self queue:videoQueue];
    
    [session addOutput:videoOutput];
    [session startRunning];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end


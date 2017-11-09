#ifndef __brf__cpp__Basic_Example_hpp
#define __brf__cpp__Basic_Example_hpp

namespace brf {

class BRFBasicCppExample {

public: std::string							_appId;

public: brf::BRFBitmapData					_bmd;
public: brf::DrawingUtils					_drawing;

public: brf::Rectangle						_brfImageRoi;
public: brf::Rectangle 						_brfFaceDectionRoi;
public: std::shared_ptr<brf::BRFManager>	_brfManager;

public: bool 								_initialized;

public: BRFBasicCppExample() :

	_appId("com.tastenkunst.brfv4.cpp.examples"), // Choose your own app id. 8 chars minimum.

	_bmd(),
	_drawing(),

	_brfImageRoi(),
	_brfFaceDectionRoi(),
	_brfManager(nullptr),

	_initialized(false)
{
}

public: virtual ~BRFBasicCppExample() {
	dispose();
}

public: void dispose() {
	if(_brfManager != nullptr) {
		reset();
		_brfManager = nullptr;
	}
}

public: void init(unsigned int width, unsigned int height, brf::ImageDataType type) {

	_bmd.init(width, height, type);
	_drawing.updateLayout(width, height);

	_brfImageRoi.setTo(0, 0, width, height);
	_brfFaceDectionRoi.setTo(0, 0, width, height);

	// Initialize BRF with the image data and the region of interest.
	// It's the same size in this case (-> analyzing the whole image).

	_brfManager = brf::BRFManager::getInstance();
	_brfManager->onReady = [this]{

		double size = _brfImageRoi.height;

		if(_brfImageRoi.width < _brfImageRoi.height) {
			size = _brfImageRoi.width;
		}

		_brfManager->setFaceDetectionParams(		size * 0.30, size * 1.00, 12, 8);
		_brfManager->setFaceTrackingStartParams(	size * 0.30, size * 1.00, 22, 26, 22);
		_brfManager->setFaceTrackingResetParams(	size * 0.25, size * 1.00, 40, 55, 32);

		initCurrentExample(*_brfManager, _brfImageRoi);
		_initialized = true;
	};

	_brfManager->init(&_bmd, &_brfImageRoi, &_appId);
}

public: void reset() {
	if(_brfManager != nullptr) {
		_brfManager->reset();
	}
}

public: void update(uint8_t* imageData) {
	_bmd.updateData(imageData);
	updateCurrentExample(*_brfManager, _drawing);
}

// Above this point every example should be the same
// The following methods set up BRF parameters and draw the expected results.

public: virtual void initCurrentExample(brf::BRFManager& brfManager, brf::Rectangle& resolution) = 0;
public: virtual void updateCurrentExample(brf::BRFManager& brfManager, brf::DrawingUtils& _drawing) = 0;

};

}

#endif // __brf__cpp__Basic_Example_hpp

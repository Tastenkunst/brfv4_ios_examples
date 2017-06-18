#ifndef __brf__cpp__BRFCppExample_hpp
#define __brf__cpp__BRFCppExample_hpp

namespace brf {

class BRFCppExample: public BRFBasicCppExample {

public: brf::Point p0;
public: brf::Point p1;

public: BRFCppExample() : BRFBasicCppExample(),
	p0(),
	p1()
{
}

public: void initCurrentExample(brf::BRFManager& brfManager, brf::Rectangle& resolution) {

	brf::trace("BRFv4 - intermediate - face tracking - simple smile detection." + brf::to_string("\n")+
		"Detects how much someone is smiling.");
}

public: void updateCurrentExample(brf::BRFManager& brfManager, brf::DrawingUtils& draw) {

	brfManager.update();

	draw.clear();

	// Face detection results: a rough rectangle used to start the face tracking.

	draw.drawRects(brfManager.getAllDetectedFaces(),	false, 1.0, 0x00a1ff, 0.5);
	draw.drawRects(brfManager.getMergedDetectedFaces(),	false, 2.0, 0xffd200, 1.0);

	std::vector< std::shared_ptr<brf::BRFFace> >& faces = brfManager.getFaces(); // default: one face, only one element in that array.

	for(size_t i = 0; i < faces.size(); i++) {

		brf::BRFFace& face = *faces[i];

		if(		face.state == brf::BRFState::FACE_TRACKING_START ||
				face.state == brf::BRFState::FACE_TRACKING) {

			// Smile Detection

			setPoint(face.vertices, 48, p0); // mouth corner left
			setPoint(face.vertices, 54, p1); // mouth corner right

			double mouthWidth = calcDistance(p0, p1);

			setPoint(face.vertices, 39, p1); // left eye inner corner
			setPoint(face.vertices, 42, p0); // right eye outer corner

			double eyeDist = calcDistance(p0, p1);
			double smileFactor = mouthWidth / eyeDist;

			smileFactor -= 1.40; // 1.40 - neutral, 1.70 smiling

			if(smileFactor > 0.25) smileFactor = 0.25;
			if(smileFactor < 0.00) smileFactor = 0.00;

			smileFactor *= 4.0;

			if(smileFactor < 0.0) { smileFactor = 0.0; }
			if(smileFactor > 1.0) { smileFactor = 1.0; }

			// Let the color show you how much you are smiling.

			uint32_t color =
					((((uint32_t)(0xff * (1.0 - smileFactor)) & 0xff) << 16)) +
					(((uint32_t)(0xff * smileFactor) & 0xff) << 8);

			// Face Tracking results: 68 facial feature points.

			draw.drawTriangles(	face.vertices, face.triangles, false, 1.0, color, 0.4);
			draw.drawVertices(	face.vertices, 2.0, false, color, 0.4);

			brf::trace(brf::to_string((int)(smileFactor * 100)) + "%");
		}
	}
};

private: inline void setPoint(std::vector< double >& v, int i, brf::Point& p) {
	brf::BRFv4PointUtils::setPoint(v, i, p);
}

private: inline double calcDistance(brf::Point& p0, brf::Point& p1) {
	return brf::BRFv4PointUtils::calcDistance(p0, p1);
}

};

}
#endif // __brf__cpp__BRFCppExample_hpp

//
//  ContentView.swift
//  testCamera
//
//  Created by Alexey on 20.10.2021.
//

import SwiftUI
import AVFoundation
import AVKit

struct ContentView: View {
    var body: some View {
        
        CameraView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct CameraView: View {

    @StateObject var camera = CameraModel()
    @State var isRecord = false

    @State var timeRemaining = 15
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()


    var body: some View {
        ZStack {
            //Color.black
            CameraPreview(camera: camera)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                if isRecord {
                    Button(action: {
                        isRecord = false
                        camera.stopRecording()
                    }, label: {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 60, height: 60)

                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 75, height: 75)

                            Text("\(timeRemaining)")
                                .foregroundColor(.black)
                                .onReceive(timer) { _ in
                                    if timeRemaining > 1 {
                                        timeRemaining -= 1
                                    } else {
                                        camera.stopRecording()
                                        isRecord = false
                                    }
                                }

                        }
                    })
                } else {
                    Button(action: {
                        isRecord = true
                        timeRemaining = 15
                        camera.recordVideo()
                    }, label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)

                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 75, height: 75)

                        }
                    })
                }
            }
        }.onAppear{
            camera.check()
            camera.checkAudio()
        }
    }

}

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {

    // @Published var isTaken = false
    @Published var session = AVCaptureSession()

    @Published var output = AVCapturePhotoOutput()
    @Published var videoOutput = AVCaptureMovieFileOutput()

    @Published var preview: AVCaptureVideoPreviewLayer!

    //@Published var isSaved = false
    // @Published var picData = Data(count: 0)
    //@Published var videoData = Data(count: 0)

    func check() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                guard granted else { return }
            }
            DispatchQueue.main.async {
                self.setUp()
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            setUp()
        @unknown default:
            break
        }
    }

    func checkAudio() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                guard granted else { return }
            }
            DispatchQueue.main.async {
                self.setUp()
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            setUp()
        @unknown default:
            break
        }
    }


    func setUp() {

        //if let device = AVCaptureDevice.default(for: .video) {
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            if let audio = AVCaptureDevice.default(for: .audio) {
                do {

                    let video = try AVCaptureDeviceInput(device: device)
                    let inputAudio = try AVCaptureDeviceInput(device: audio)

                    if session.canAddInput(inputAudio) {
                        session.addInput(inputAudio)
                    }

                    if session.canAddInput(video) {
                        session.addInput(video)
                    }


//                    if session.canAddOutput(output) {
//                        session.addOutput(output)
//                    }

                    if session.canAddOutput(videoOutput) {
                        session.addOutput(videoOutput)
                    }

//                    if session.canAddOutput(voiceOutput) {
//                        session.addOutput(voiceOutput)
//                    }

                    session.startRunning()
                }
                catch {

                }
            }
        }
    }

//  чтобы делать фотки:
//
//    func takePicture() {
//        DispatchQueue.global(qos: .background).async {
//            self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
//            self.session.stopRunning()
//
//            DispatchQueue.main.async {
//                withAnimation { self.isTaken.toggle() }
//            }
//        }
//    }
//
//    func reTakePicture() {
//        DispatchQueue.global(qos: .background).sync {
//            self.session.startRunning()
//
//            DispatchQueue.main.async {
//                withAnimation { self.isTaken.toggle() }
//                self.isTaken = false
//            }
//
//
//        }
//    }
//
//    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
//        if error != nil {
//            return
//        }
//
//        guard let imageDate = photo.fileDataRepresentation() else { return }
//
//
//
//        self.picData = imageDate
//    }

    func recordVideo() {
        print("record...")
        DispatchQueue.global(qos: .background).async {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileUrl = paths[0].appendingPathComponent("output.mov")
            try? FileManager.default.removeItem(at: fileUrl)
            self.videoOutput.startRecording(to: fileUrl, recordingDelegate: self)
        }
    }

    func stopRecording() {
        print("stop...")
        DispatchQueue.global(qos: .background).async {
            self.videoOutput.stopRecording()
        }

    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("output...")
        if error != nil {
            return
            //do something
        }
        UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)

    }

//    func savePicture() {
//        let image = UIImage(data: self.picData)!
//
//        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
//
//        isSaved = true
//    }

}

struct CameraPreview: UIViewRepresentable {

    @ObservedObject var camera: CameraModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)

        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)

        camera.preview.frame = view.frame

        camera.preview.videoGravity = .resizeAspectFill

        view.layer.addSublayer(camera.preview)

        self.camera.session.startRunning()

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {

    }

}

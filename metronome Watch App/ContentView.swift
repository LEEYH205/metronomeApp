//
//  ContentView.swift
//  metronome Watch App
//
//  Created by 이영호 on 9/13/24.
//
import SwiftUI
import AVFoundation
import WatchKit

struct ContentView: View {
    @State private var tempo: Int = 120  // 기본 템포 (BPM) 120으로 설정
    @State private var isPlaying: Bool = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var metronomeTimer: DispatchSourceTimer?
    @State private var crownValue: Double = 120.0  // 디지털 크라운 값도 120으로 설정
    let hapticFeedback = WKInterfaceDevice.current()

    var body: some View {
        VStack {
            Text("\(tempo) BPM")
                .font(.system(size: 24))
                .padding()
                // 디지털 크라운 회전으로 템포 조정
                .focusable(true)
                .digitalCrownRotation($crownValue, from: 20.0, through: 240.0, by: 1.0, sensitivity: .medium, isContinuous: false)
                .onChange(of: crownValue) { newValue in
                    tempo = Int(newValue)
                    updateMetronomeTempo()
                }

            HStack {
                Button(action: {
                    if tempo > 20 {  // 최소 템포 제한
                        tempo -= 1
                        crownValue = Double(tempo)  // 디지털 크라운 값도 업데이트
                        updateMetronomeTempo()
                    }
                }) {
                    Text("-")
                        .font(.system(size: 36))
                        .frame(width: 50, height: 50)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }

                Button(action: {
                    if tempo < 240 {  // 최대 템포 제한
                        tempo += 1
                        crownValue = Double(tempo)  // 디지털 크라운 값도 업데이트
                        updateMetronomeTempo()
                    }
                }) {
                    Text("+")
                        .font(.system(size: 36))
                        .frame(width: 50, height: 50)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }
            .padding()

            Button(action: {
                isPlaying.toggle()
                if isPlaying {
                    startMetronome()
                } else {
                    stopMetronome()
                }
            }) {
                Text(isPlaying ? "Stop" : "Start")
                    .font(.system(size: 24))
                    .padding()
                    .background(isPlaying ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .onAppear {
            prepareSound()
            crownValue = Double(tempo)  // 디지털 크라운 값을 템포와 동기화
        }
    }

    // 소리 파일 준비
    func prepareSound() {
        if let path = Bundle.main.path(forResource: "tick", ofType: "mp3") {
            let url = URL(fileURLWithPath: path)
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.prepareToPlay()
            } catch {
                print("오디오 파일 로드 실패: \(error)")
            }
        }
    }

    // 메트로놈 시작
    func startMetronome() {
        let interval = 60.0 / Double(tempo)  // BPM을 초 간격으로 변환
        metronomeTimer = DispatchSource.makeTimerSource()
        metronomeTimer?.schedule(deadline: .now(), repeating: interval)
        
        metronomeTimer?.setEventHandler {
            DispatchQueue.main.async {
                self.playTickSound()
                self.triggerHapticFeedback()
            }
        }
        metronomeTimer?.resume()
    }

    // 메트로놈 정지
    func stopMetronome() {
        metronomeTimer?.cancel()
        metronomeTimer = nil
    }

    // 템포가 변경될 때 메트로놈을 즉시 업데이트
    func updateMetronomeTempo() {
        if isPlaying {
            stopMetronome()  // 현재 타이머 중지
            startMetronome()  // 새로운 템포로 재시작
        }
    }

    // 소리 재생
    func playTickSound() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }

    // 햅틱 피드백 (진동) 발생
    func triggerHapticFeedback() {
        hapticFeedback.play(.click)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//
//  BackgroundMetronome.swift
//  metronome Watch App
//
//  Created by 이영호 on 9/14/24.
//
import Foundation
import AVFoundation
import HealthKit
import Combine
import WatchKit


class BackgroundMetronome: NSObject, ObservableObject {
    @Published var tempo: Int = 120
    @Published var isPlaying: Bool = false

    private var audioPlayer: AVAudioPlayer?
    private var metronomeTimer: Timer?
    private let hapticFeedback = WKInterfaceDevice.current()

    override init() {
        super.init()
        prepareSound()
    }

    func prepareSound() {
        if let path = Bundle.main.path(forResource: "tick", ofType: "mp3") {
            let url = URL(fileURLWithPath: path)
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.prepareToPlay()
                audioPlayer?.numberOfLoops = -1 // 무한 반복
                print("오디오 파일이 성공적으로 로드되었습니다.")
            } catch {
                print("오디오 파일 로드 실패: \(error)")
            }
        } else {
            print("오디오 파일을 찾을 수 없습니다.")
        }
    }

    func startMetronome() {
        isPlaying = true
        let interval = 60.0 / Double(tempo)
        metronomeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.playTickSound()
            self?.triggerHapticFeedback()
        }
    }

    func stopMetronome() {
        isPlaying = false
        metronomeTimer?.invalidate()
        metronomeTimer = nil
        audioPlayer?.stop()
    }

    func updateMetronomeTempo() {
        if isPlaying {
            stopMetronome()
            startMetronome()
        }
    }

    func playTickSound() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }

    func triggerHapticFeedback() {
        hapticFeedback.play(.click)
    }
}

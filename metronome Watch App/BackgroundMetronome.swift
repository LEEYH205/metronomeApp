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
import MediaPlayer

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
        print("startMetronome")
        print("isPlaying : \(isPlaying)")
        configureAudioSession()

        do {
            try AVAudioSession.sharedInstance().setActive(true)
            print("메트로놈 시작 전 오디오 세션 활성화 성공")
        } catch {
            print("메트로놈 시작 전 오디오 세션 활성화 실패: \(error)")
        }
        
        guard !isPlaying else {
            print("메트로놈이 이미 실행 중입니다.")
            return
        }
        isPlaying = true
        updateNowPlayingInfo()
        UserDefaults.standard.set(true, forKey: "metronomeIsPlaying")
        let interval = 60.0 / Double(tempo)
        /*
        metronomeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.playTickSound()
            self?.triggerHapticFeedback()
        }
        RunLoop.current.add(metronomeTimer!, forMode: .common)  // 이 줄을 추가
*/
        metronomeTimer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.playTickSound()
            self?.triggerHapticFeedback()
            self?.updateNowPlayingInfo()
        }
        RunLoop.main.add(metronomeTimer!, forMode: .common)
        
        print("Audio session category set: \(AVAudioSession.sharedInstance().category)")
        print("Audio session active: \(AVAudioSession.sharedInstance().isOtherAudioPlaying)")
        // 디버깅 로그 추가
        print("메트로놈 시작, isPlaying: \(isPlaying)")
    }

    func stopMetronome() {
        print("stopMetronome")
        print("isPlaying : \(isPlaying)")
        
        guard isPlaying else {
            print("메트로놈이 실행 중이åç지 않습니다.")
            return
        }
        isPlaying = false
        updateNowPlayingInfo()
        UserDefaults.standard.set(false, forKey: "metronomeIsPlaying")
        metronomeTimer?.invalidate()
        metronomeTimer = nil
        audioPlayer?.stop()
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("메트로놈 정지 후 오디오 세션 비활성화 성공")
        } catch {
            print("메트로놈 정지 후 오디오 세션 비활성화 실패: \(error)")
        }
    }
    func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Metronome"
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = isPlaying ? 1 : 0
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 1
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1 : 0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func updateMetronomeTempo() {
        //let wasPlaying = UserDefaults.standard.bool(forKey: "metronomeIsPlaying")
        if isPlaying {
            stopMetronome()
            startMetronome()
        }
    }

    func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            print("오디오 세션 구성 성공")
        } catch {
            print("오디오 세션 구성 실패: \(error)")
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

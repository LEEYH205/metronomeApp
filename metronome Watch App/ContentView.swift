//
//  ContentView.swift
//  metronome Watch App
//
//  Created by 이영호 on 9/13/24.
//
import SwiftUI
import AVFoundation
import WatchKit
import HealthKit

class BackgroundMetronome: NSObject, ObservableObject {
    @Published var tempo: Int = 120
    @Published var isPlaying: Bool = false
    
    private var audioPlayer: AVAudioPlayer?
    private var metronomeTimer: Timer?
    private let hapticFeedback = WKInterfaceDevice.current()
    
    // HealthKit 관련 설정
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    override init() {
        super.init()
        prepareSound()
        setupAudioSession()
        requestWorkoutAuthorization()
    }
    
    // 오디오 파일을 로드하여 메트로놈 소리 준비
    func prepareSound() {
        if let path = Bundle.main.path(forResource: "tick", ofType: "mp3") {
            let url = URL(fileURLWithPath: path)
            audioPlayer = try? AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.numberOfLoops = -1 // 무한 반복
        }
    }
    
    // 오디오 세션 설정
    func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("오디오 세션 설정 실패: \(error)")
        }
    }
    
    // 메트로놈을 시작
    func startMetronome() {
        isPlaying = true
        let interval = 60.0 / Double(tempo)
        metronomeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.playTickSound()
            self?.triggerHapticFeedback()
        }
        //startWorkoutSession()
    }
    
    // 메트로놈을 멈춤
    func stopMetronome() {
        isPlaying = false
        metronomeTimer?.invalidate()
        metronomeTimer = nil
        audioPlayer?.stop()
        //endWorkoutSession()
    }
    
    // 템포 변경 시 메트로놈을 다시 시작
    func updateMetronomeTempo() {
        if isPlaying {
            stopMetronome()
            startMetronome()
        }
    }
    
    // 소리 재생
    func playTickSound() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }
    
    // 진동 재생
    func triggerHapticFeedback() {
        hapticFeedback.play(.click)
    }
    
    // HealthKit 권한 요청
    func requestWorkoutAuthorization() {
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [HKObjectType.quantityType(forIdentifier: .heartRate)!]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            if !success {
                print("HealthKit 권한 요청 실패: \(String(describing: error))")
            }
        }
    }
    
    // 운동 세션 시작
    func startWorkoutSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .indoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = workoutSession?.associatedWorkoutBuilder()
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            workoutSession?.startActivity(with: Date())
            builder?.beginCollection(withStart: Date()) { (success, error) in
                if !success {
                    print("워크아웃 데이터 수집 시작 실패: \(String(describing: error))")
                }
            }
        } catch {
            print("워크아웃 세션 시작 실패: \(error)")
        }
    }
    
    // 운동 세션 종료
    func endWorkoutSession() {
        workoutSession?.end()
        builder?.endCollection(withEnd: Date()) { (success, error) in
            if !success {
                print("워크아웃 데이터 수집 종료 실패: \(String(describing: error))")
            }
            self.builder?.finishWorkout { (workout, error) in
                if let error = error {
                    print("워크아웃 종료 실패: \(error)")
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var metronome = BackgroundMetronome()
    @State private var crownValue: Double = 120.0
    
    var body: some View {
        VStack {
            Text("\(metronome.tempo) BPM")
                .font(.system(size: 24))
                .padding()
                .focusable(true)
                .digitalCrownRotation($crownValue, from: 20.0, through: 240.0, by: 1.0, sensitivity: .medium, isContinuous: false)
                .onChange(of: crownValue) { newValue in
                    metronome.tempo = Int(newValue)
                    metronome.updateMetronomeTempo()
                }
            
            HStack {
                Button(action: {
                    if metronome.tempo > 20 {
                        metronome.tempo -= 1
                        crownValue = Double(metronome.tempo)
                        metronome.updateMetronomeTempo()
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
                    if metronome.tempo < 240 {
                        metronome.tempo += 1
                        crownValue = Double(metronome.tempo)
                        metronome.updateMetronomeTempo()
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
                if metronome.isPlaying {
                    metronome.stopMetronome()
                } else {
                    metronome.startMetronome()
                }
            }) {
                Text(metronome.isPlaying ? "Stop" : "Start")
                    .font(.system(size: 24))
                    .padding()
                    .background(metronome.isPlaying ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .onAppear {
            crownValue = Double(metronome.tempo)
        }
    }
}


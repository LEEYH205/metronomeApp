//
//  ExtensionDelegate.swift
//  metronome Watch App
//
//  Created by 이영호 on 9/14/24.
//
import Foundation
import WatchKit
import AVFoundation
import HealthKit


class ExtensionDelegate: NSObject, WKExtensionDelegate, ObservableObject {
    var savedTask: WKRefreshBackgroundTask?
    var metronome = BackgroundMetronome()
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?

    static func shared() -> ExtensionDelegate {
        return WKExtension.shared().delegate as! ExtensionDelegate
    }
    
    func applicationDidFinishLaunching() {
        print("applicationDidFinishLaunching")
        setupAudioSession()
        requestWorkoutAuthorization()
    }
    func applicationDidBecomeActive() {
        //scheduleBackgroundRefresh()
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch  {
            print("AVAudioSession setActive error %@", error.localizedDescription)
        }
    }
    /*
    func applicationDidEnterBackground() {
        print("applicationDidEnterBackground-1")
        //setupAudioSession()
        print("applicationDidEnterBackground-2")

        
        print("applicationDidEnterBackground metronome.isPlaying : \(metronome.isPlaying)")
        if(metronome.isPlaying) {
            UserDefaults.standard.set(true, forKey: "metronomeIsPlaying")
        }
        else {
            UserDefaults.standard.set(false, forKey: "metronomeIsPlaying")
        }
        //let wasPlaying = UserDefaults.standard.bool(forKey: "metronomeIsPlaying")
        //if wasPlaying {
        if metronome.isPlaying {
            print("applicationDidEnterBackground 백그라운드에서 메트로놈 재생 유지")
            //metronome.stopMetronome()
            //setupAudioSession()
            //metronome.startMetronome()
            do {
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                print("백그라운드에서 오디오 세션 활성화 유지 성공")
            } catch {
                print("백그라운드에서 오디오 세션 활성화 유지 실패: \(error)")
            }
           
            
        } else {
            print("applicationDidEnterBackground 메트로놈이 재생 중이 아님")
            metronome.startMetronome()
        }
        scheduleBackgroundRefresh()
        print("Audio session category set: \(AVAudioSession.sharedInstance().category)")
        print("Audio session active: \(AVAudioSession.sharedInstance().isOtherAudioPlaying)")
    }
*/
    func applicationDidEnterBackground() {
        print("applicationDidEnterBackground-1")
        
        let wasPlaying = UserDefaults.standard.bool(forKey: "metronomeIsPlaying")
        if wasPlaying {
        //if metronome.isPlaying {
            do {
                //try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
                //try AVAudioSession.sharedInstance().setActive(true)
                metronome.updateNowPlayingInfo() // 백그라운드에서도 정보 업데이트
                print("백그라운드에서 오디오 세션 활성화 유지 성공")
            } catch {
                print("백그라운드에서 오디오 세션 활성화 유지 실패: \(error)")
            }
            // 백그라운드 작업 스케줄링
            scheduleBackgroundRefresh()
        }
        
        
        //print("applicationDidEnterBackground metronome.isPlaying : \(metronome.isPlaying)")
        //UserDefaults.standard.set(metronome.isPlaying, forKey: "metronomeIsPlaying")
        
        print("Audio session category set: \(AVAudioSession.sharedInstance().category)")
        print("Audio session active: \(AVAudioSession.sharedInstance().isOtherAudioPlaying)")
    }
    
    func applicationWillEnterForeground() {
        print("applicationWillEnterForeground")
        let wasPlaying = UserDefaults.standard.bool(forKey: "metronomeIsPlaying")
        print("applicationWillEnterForeground metronome.isPlaying-1: \(metronome.isPlaying)")
        metronome.isPlaying = wasPlaying
        print("applicationWillEnterForeground metronome.isPlaying-2: \(metronome.isPlaying)")

    }
/*
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if let backgroundTask = task as? WKApplicationRefreshBackgroundTask {
                // 백그라운드 리프레시 작업 실행 시 호출
                print("백그라운드 리프레시 작업 실행")
                
                // 백그라운드에서 메트로놈이 계속 실행되도록 유지
                let wasPlaying = UserDefaults.standard.bool(forKey: "metronomeIsPlaying")
                if wasPlaying {
                //if metronome.isPlaying {
                    print("handle 백그라운드에서 메트로놈 유지")
                    metronome.startMetronome()
                }
                else{
                    print("handle 백그라운드에서 메트로놈 시작")
                    //metronome.startMetronome()
                }
                
                // 백그라운드 작업 완료 처리
                backgroundTask.setTaskCompletedWithSnapshot(true)
            } else {
                task.setTaskCompletedWithSnapshot(true)
            }
        }
    }
*/
    /*
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // 백그라운드 작업 수행
                // ...
                let wasPlaying = UserDefaults.standard.bool(forKey: "metronomeIsPlaying")
                if wasPlaying {
                //if metronome.isPlaying {
                    print("handle 백그라운드에서 메트로놈 유지")
                    metronome.startMetronome()
                }
                else{
                    print("handle 백그라운드에서 메트로놈 시작")
                    //metronome.startMetronome()
                }
                backgroundTask.setTaskCompletedWithSnapshot(false)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
*/
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                if metronome.isPlaying {
                    //metronome.configureAudioSession()
                    print("handle 백그라운드에서 메트로놈 유지")
                    // 메트로놈이 계속 실행 중이라면 다음 백그라운드 리프레시를 스케줄링
                    scheduleBackgroundRefresh()
                }
                backgroundTask.setTaskCompletedWithSnapshot(false)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            print("오디오 세션 설정 성공")
            print("Audio session category set: \(AVAudioSession.sharedInstance().category)")
            print("Audio session active: \(AVAudioSession.sharedInstance().isOtherAudioPlaying)")
        } catch {
            print("오디오 세션 설정 실패: \(error)")
        }
    }

    private func requestWorkoutAuthorization() {
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [HKObjectType.quantityType(forIdentifier: .heartRate)!]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            if !success {
                print("HealthKit 권한 요청 실패: \(String(describing: error))")
            }
        }
    }

    func scheduleBackgroundRefresh() {
        print("scheduleBackgroundRefresh")
        let nextRefreshDate = Date(timeIntervalSinceNow: 5) // 5초 후에 백그라운드 리프레시 스케줄링
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: nextRefreshDate, userInfo: nil) { (error) in
            if let error = error {
                print("Background refresh scheduling failed: \(error)")
            } else {
                print("Background refresh scheduling success")
            }
        }
    }
    /*
    func scheduleBackgroundRefresh() {
        print("scheduleBackgroundRefresh")
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date(timeIntervalSinceNow: 30), userInfo: nil) { (error) in
            if let error = error {
                print("Background refresh scheduling failed: \(error)")
            }
            else{
                print("Background refresh scheduling success")
            }
        }
    }
*/
    func startWorkoutSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .indoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutSession?.startActivity(with: Date())
            print("워크아웃 세션 시작 성공")
        } catch {
            print("워크아웃 세션 시작 실패: \(error)")
        }
    }

    func endWorkoutSession() {
        workoutSession?.end()
    }
}

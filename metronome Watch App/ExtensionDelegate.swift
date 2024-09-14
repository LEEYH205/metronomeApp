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

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    private var audioSession: AVAudioSession?
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    
    func applicationDidFinishLaunching() {
        setupAudioSession()
        requestWorkoutAuthorization()
    }
    
    func applicationDidEnterBackground() {
        // 애플워치가 백그라운드로 들어갈 때 오디오 세션을 설정합니다.
        setupAudioSession()
        scheduleBackgroundRefresh()
    }
    
    func applicationWillEnterForeground() {
        // 애플워치가 포그라운드로 돌아올 때 필요한 설정을 합니다.
        // 예를 들어, 오디오 세션을 다시 활성화할 수 있습니다.
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if task is WKWatchConnectivityRefreshBackgroundTask {
                task.setTaskCompletedWithSnapshot(true)
            } else {
                task.setTaskCompletedWithSnapshot(true)
            }
        }
    }
    
    private func setupAudioSession() {
        do {
            if audioSession == nil {
                audioSession = AVAudioSession.sharedInstance()
            }
            try audioSession?.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession?.setActive(true)
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
    
    private func scheduleBackgroundRefresh() {
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date(timeIntervalSinceNow: 60), userInfo: nil) { (error) in
            if let error = error {
                print("Background refresh scheduling failed: \(error)")
            }
        }
    }
    
    func startWorkoutSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .indoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutSession?.startActivity(with: Date())
        } catch {
            print("워크아웃 세션 시작 실패: \(error)")
        }
    }
    
    func endWorkoutSession() {
        workoutSession?.end()
    }
}


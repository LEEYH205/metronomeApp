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
    var metronome = BackgroundMetronome()
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?

    func applicationDidFinishLaunching() {
        setupAudioSession()
        requestWorkoutAuthorization()
    }

    func applicationDidEnterBackground() {
        print("applicationDidEnterBackground-1")

        setupAudioSession()
        print("applicationDidEnterBackground-2")

        if metronome.isPlaying {
            metronome.startMetronome()
        }
        scheduleBackgroundRefresh()
    }

    func applicationWillEnterForeground() {
        print("applicationWillEnterForeground")
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            task.setTaskCompletedWithSnapshot(true)
        }
    }

    func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            print("오디오 세션 설정 성공")
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
            print("워크아웃 세션 시작 성공")
        } catch {
            print("워크아웃 세션 시작 실패: \(error)")
        }
    }

    func endWorkoutSession() {
        workoutSession?.end()
    }
}

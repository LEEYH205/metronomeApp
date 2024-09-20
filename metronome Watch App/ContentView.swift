//
//  ContentView.swift
//  metronome Watch App
//
//  Created by 이영호 on 9/13/24.
//
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var extensionDelegate: ExtensionDelegate
    
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
                    metronome.tempo = Int(newValue) // Int로 변환하여 tempo 업데이트
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

//
//  ContentView.swift
//  sudoku
//

import SwiftUI

private let initialValues: [Int?] = [18, nil, 17, nil, nil, nil, nil, nil, nil, nil, 13, 11, nil, nil, 12, 14, nil, nil, nil, 14, nil, nil, nil, nil, nil, 15, 12, 19, 16, nil, 14, 11, nil, 18, 17, nil, 11, nil, nil, 17, nil, 13, 19, 12, nil, nil, nil, 14, 19, nil, 18, 11, nil, nil, 14, nil, 16, 11, nil, 17, 12, 13, nil, 17, 15, 13, nil, nil, nil, nil, 19, 11, nil, 11, nil, nil, nil, 16, 15, 14, nil]

struct ContentView: View {
    @State private var selectedRow: Int?
    @State private var selectedCol: Int?
    @State private var values: [Int?] = initialValues

    var body: some View {
        HStack(alignment: .bottom) {
            GridView(
                selectedRow: $selectedRow,
                selectedCol: $selectedCol,
                values: values
            )
            .layoutPriority(1)

            KeyboardView { number in
                guard let row = selectedRow, let col = selectedCol else {
                    return
                }
                
                values[9 * row + col] = number
            } onNewGame: {
                values = initialValues
                selectedRow = nil
                selectedCol = nil
            } onDelete: {
                guard let row = selectedRow, let col = selectedCol else {
                    return
                }
                
                values[9 * row + col] = nil
            }
        }
        .padding()
        .onAppear {
            if let saved = Storage.load() {
                values = saved
            }
        }
        .onChange(of: values) {
            Storage.save(values)
        }
    }
}

#Preview {
    ContentView()
}

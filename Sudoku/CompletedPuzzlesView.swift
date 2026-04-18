//
//  CompletedPuzzlesView.swift
//  Sudoku
//

import SwiftUI

struct CompletedPuzzlesView: View {
    var viewModel: PuzzleViewModel
    @State private var sortOrder = SortOrder.difficulty
    @State private var ascending = true
    @State private var replayEntry: CompletedPuzzle?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.customFontOption) private var fontOption
    
    var body: some View {
        Group {
            if viewModel.completedPuzzles.isEmpty {
                ContentUnavailableView {
                    Label("No Completed Puzzles", systemImage: "trophy")
                        .font(fontOption.font(for: .headline))
                } description: {
                    Text("Puzzles you solve will appear here.")
                        .font(fontOption.font(for: .subheadline))
                }
            } else {
                List(sorted) { entry in
                    Button {
                        replayEntry = entry
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Puzzle #\(entry.catalogID)")
                                    .font(fontOption.font(for: .headline))
                                Text(localizedDifficulty(entry.difficulty))
                                    .font(fontOption.font(for: .subheadline))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.completedAt, format: .dateTime)
                                    .foregroundStyle(.secondary)
                                Label(Self.formatTime(entry.elapsedTime), systemImage: "clock")
                                    .foregroundStyle(.secondary)
                                Label("\(entry.hintCount)", systemImage: "lightbulb.fill")
                                    .foregroundStyle(.orange)
                                Label("\(entry.errorCount)", systemImage: "xmark")
                                    .foregroundStyle(entry.errorCount == 0 ? .green : .red)
                            }
                            .font(fontOption.font(for: .subheadline))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Completed Puzzles")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button {
                            if sortOrder == order {
                                ascending.toggle()
                            } else {
                                sortOrder = order
                                ascending = true
                            }
                        } label: {
                            Label(
                                order.label,
                                systemImage: sortOrder == order
                                ? (ascending ? "chevron.up" : "chevron.down")
                                : order.icon
                            )
                        }
                    }
                } label: {
                    Image(systemName: ascending ? "arrow.up" : "arrow.down")
                }
            }
        }
        .confirmationDialog(
            "Play Again?",
            isPresented: Binding(get: { replayEntry != nil }, set: { if !$0 { replayEntry = nil } }),
            titleVisibility: .visible
        ) {
            if let entry = replayEntry {
                Button("Replay Puzzle #\(entry.catalogID)") {
                    _ = viewModel.loadGameByID(entry.catalogID)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let entry = replayEntry {
                Text("Would you like to replay puzzle #\(entry.catalogID)?")
            }
        }
    }
    
    private enum SortOrder: CaseIterable {
        case difficulty, hints, errors, time
        
        var label: String {
            switch self {
            case .difficulty: String(localized: "Difficulty")
            case .hints:      String(localized: "Hints used")
            case .errors:     String(localized: "Errors")
            case .time:       String(localized: "Time")
            }
        }
        
        var icon: String {
            switch self {
            case .difficulty: "chart.bar"
            case .hints:      "lightbulb"
            case .errors:     "xmark.circle"
            case .time:       "clock"
            }
        }
    }
    
    private static let difficultyRank: [String: Int] = [
        "easy": 0, "medium": 1, "hard": 2, "expert": 3
    ]
    
    private var sorted: [CompletedPuzzle] {
        viewModel.completedPuzzles.sorted { a, b in
            let result: Bool
            switch sortOrder {
            case .difficulty:
                let ra = Self.difficultyRank[a.difficulty.lowercased()] ?? 99
                let rb = Self.difficultyRank[b.difficulty.lowercased()] ?? 99
                result = ra < rb
            case .hints:
                result = a.hintCount < b.hintCount
            case .errors:
                result = a.errorCount < b.errorCount
            case .time:
                result = a.elapsedTime < b.elapsedTime
            }
            return ascending ? result : !result
        }
    }
    
    private static func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        CompletedPuzzlesView(viewModel: PuzzleViewModel(puzzle: .sample))
    }
}

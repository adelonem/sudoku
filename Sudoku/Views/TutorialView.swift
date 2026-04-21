//
//  TutorialView.swift
//  Sudoku
//

import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.customAccentColor) private var accentColor
    @Environment(\.customFontOption) private var fontOption
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                heroCard
                objectiveCard
                controlsCard
                toolsCard
                infoCard
            }
            .frame(maxWidth: 760, alignment: .top)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(backgroundGradient.ignoresSafeArea())
        .navigationTitle("How to Play")
        .safeAreaInset(edge: .bottom) {
            navigationStrip
        }
    }
    
    private var navigationStrip: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("Start Playing")
                        .font(fontOption.font(for: .headline).weight(.semibold))
                        .frame(minWidth: 180)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(.thinMaterial)
    }
    
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Welcome to Sudoku", systemImage: "graduationcap.fill")
                .font(fontOption.font(for: .title3).weight(.semibold))
                .foregroundStyle(accentColor)
            
            Text("This quick guide shows the goal of the puzzle, the touch gestures used in the grid, and the tools available while you play.")
                .font(fontOption.font(for: .body))
                .foregroundStyle(.primary)
            
            Text("You can reopen this tutorial any time from the information menu in the toolbar.")
                .font(fontOption.font(for: .subheadline))
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }
    
    private var objectiveCard: some View {
        tutorialCard(
            title: "Goal",
            systemImage: "target",
            items: [
                TutorialItem(
                    id: "goal-grid",
                    title: "Fill every row, column, and 3×3 box",
                    detail: "Each area must contain the digits 1 to 9 exactly once."
                ),
                TutorialItem(
                    id: "goal-fixed",
                    title: "Fixed digits stay in place",
                    detail: "The numbers given at the start cannot be changed."
                ),
                TutorialItem(
                    id: "goal-conflicts",
                    title: "Finish without conflicts",
                    detail: "If the same digit appears twice in a row, column, or box, the grid is incorrect."
                )
            ]
        )
    }
    
    private var controlsCard: some View {
        tutorialCard(
            title: "Grid Controls",
            systemImage: "hand.tap.fill",
            items: [
                TutorialItem(
                    id: "controls-select-digit",
                    title: "Tap a digit first",
                    detail: "Use the keypad to choose the number you want to work with."
                ),
                TutorialItem(
                    id: "controls-note",
                    title: "Tap a cell to add or remove a note",
                    detail: "A simple tap toggles the selected digit as a pencil mark in the chosen cell."
                ),
                TutorialItem(
                    id: "controls-place",
                    title: "Double-tap a cell to place the digit",
                    detail: "When you are confident, a double tap writes the selected number into the grid."
                ),
                TutorialItem(
                    id: "controls-clear",
                    title: "Long-press an editable cell to clear it",
                    detail: "Use a long press to erase a guess or notes from a cell you can modify."
                )
            ]
        )
    }
    
    private var toolsCard: some View {
        tutorialCard(
            title: "Helpful Tools",
            systemImage: "wand.and.stars.inverse",
            items: [
                TutorialItem(
                    id: "tools-candidates",
                    title: "Wand",
                    detail: "Shows or hides candidate digits across the board to help you inspect possibilities."
                ),
                TutorialItem(
                    id: "tools-hint",
                    title: "Light bulb",
                    detail: "Opens a guided hint view. If a hint is already visible, tapping again hides it."
                ),
                TutorialItem(
                    id: "tools-restart",
                    title: "Restart",
                    detail: "Resets the current puzzle if you want to start over from the initial grid."
                ),
                TutorialItem(
                    id: "tools-undo",
                    title: "Undo",
                    detail: "The arrow in the header restores your previous move."
                )
            ]
        )
    }
    
    private var infoCard: some View {
        tutorialCard(
            title: "What the Header Tells You",
            systemImage: "info.circle.fill",
            items: [
                TutorialItem(
                    id: "info-clock",
                    title: "Clock",
                    detail: "Shows how long the current puzzle has been running."
                ),
                TutorialItem(
                    id: "info-hints",
                    title: "Hints",
                    detail: "Tracks how many hints or reveals you have used."
                ),
                TutorialItem(
                    id: "info-errors",
                    title: "Errors",
                    detail: "Counts incorrect placements detected in the grid."
                )
            ]
        )
    }
    
    private func tutorialCard(
        title: LocalizedStringKey,
        systemImage: String,
        items: [TutorialItem]
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: systemImage)
                .font(fontOption.font(for: .headline))
                .foregroundStyle(accentColor)
            
            VStack(alignment: .leading, spacing: 14) {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(fontOption.font(for: .subheadline).weight(.semibold))
                        Text(item.detail)
                            .font(fontOption.font(for: .body))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Style.background)
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(accentColor.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                accentColor.opacity(0.14),
                accentColor.opacity(0.05),
                Style.background
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct TutorialItem: Identifiable {
    let id: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
}

#Preview {
    NavigationStack {
        TutorialView()
            .tint(Style.accentColors[0].color)
            .environment(\.customAccentColor, Style.accentColors[0].color)
            .environment(\.customFontOption, .standard)
    }
}

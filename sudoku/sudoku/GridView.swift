//
//  GridView.swift
//  sudoku
//

import SwiftUI

struct GridView: View {
    @State private var selectedRow: Int?
    @State private var selectedCol: Int?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main 9x9 grid of squares
                Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                    ForEach(0..<9) { i in
                        GridRow {
                            ForEach(0..<9) { j in
                                let color =
                                    selectedRow == i && selectedCol == j
                                        ? Color(red: 0.760, green: 0.867, blue: 0.973, opacity: 1.0)
                                        : selectedRow == i || selectedCol == j
                                            ? Color(red: 0.890, green: 0.922, blue: 0.949, opacity: 1.0)
                                            : Color.white
  
                                Rectangle()
                                    .fill(color)
                                    .aspectRatio(1.0, contentMode: .fit)
                                    .border(.gray.opacity(0.6), width: 0.5)
                                    .onTapGesture {
                                        selectedRow = i;
                                        selectedCol = j;
                                    }
                            }
                        }
                    }
                }

                // Thick lines to outline each 3x3 block
                let size = min(geometry.size.width, geometry.size.height)
                let size2 = size / 2
                let size3 = size / 3
                ForEach(0..<4) { i in
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: size, height: 2)
                        .offset(y: size3 * CGFloat(i) - size2)
                    
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 2, height: size)
                        .offset(x: size3 * CGFloat(i) - size2)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

#Preview {
    GridView()
}

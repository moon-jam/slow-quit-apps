import SwiftUI

/// Quit Progress Overlay View
/// Shows circular progress bar and app name, uses Liquid Glass effect
struct QuitOverlayView: View {
    /// Progress value (0.0 - 1.0)
    let progress: Double
    
    /// App name
    let appName: String
    
    /// Whether to show animations
    let animated: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Circular progress ring
            progressRing
            
            // App name
            Text(appName)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(24)
        .modifier(GlassBackgroundModifier())
    }
    
    /// Circular progress ring view
    private var progressRing: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color.primary.opacity(0.15),
                    lineWidth: 5
                )
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(animated ? .easeOut(duration: 0.08) : .none, value: progress)
            
            // Center Q character
            Text("Q")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(width: 56, height: 56)
    }
    
    /// Progress bar gradient
    private var progressGradient: AngularGradient {
        let colors: [Color] = switch progress {
        case ..<0.5:
            [.blue, .cyan]
        case ..<0.8:
            [.orange, .yellow]
        default:
            [.red, .pink]
        }
        
        return AngularGradient(
            colors: colors,
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * progress)
        )
    }
}

// MARK: - Liquid Glass Background Modifier

/// Selects the appropriate glass effect based on the system version
private struct GlassBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            // macOS 26+ uses Liquid Glass
            content
                .glassEffect(.regular, in: .rect(cornerRadius: 20))
        } else {
            // Lower versions use Material effect
            content
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
                )
        }
    }
}


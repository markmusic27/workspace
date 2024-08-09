import WidgetKit
import SwiftUI


struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TasksEntry {
        TasksEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (TasksEntry) -> ()) {
        let entry = TasksEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TasksEntry>) -> ()) {
        let entries = [TasksEntry()]  // Single entry
        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }
}

struct TasksEntry: TimelineEntry {
    let date = Date()  // Required by TimelineEntry protocol, but not used
}

struct TasksWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
      ZStack(alignment: .top) {
        Color(hex: 0x191919)
        TasksView()
        NavBar()
      }
      .containerBackground(for: .widget) {
        Color(hex: 0x191919)
      }
    }
}

struct CustomCircularProgressViewStyle: ProgressViewStyle {
    var lineWidth: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(configuration.fractionCompleted ?? 0))
                .stroke(Color.white.opacity(0.75), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

struct Task: Identifiable {
  let id = UUID()
  let title: String
  let description: String
  let dueDate: String
  let priority: Int
  let isComplete: Bool
}

struct TasksWidget: Widget {
    let kind: String = "TasksWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TasksWidgetEntryView(entry: entry)
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Tasks")
        .description("Displays Workspace tasks")
        .supportedFamilies([.systemLarge])
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

// Components

struct NavBar: View {
  var body: some View {
    VStack (spacing: 0) {
      ZStack {
        LinearGradient(gradient: Gradient(colors: [Color(hex: 0x474747), Color(hex:0x303030)]),
                                   startPoint: .top,
                                   endPoint: .bottom).overlay(
                                    Rectangle()
                                      .fill(Color.black.opacity(0.2))
                                      .frame(height: 1.6)
                                        .offset(y: 0)
                                    , alignment: .bottom
                                )
        HStack(spacing: 0) {
          ProgressView(value: 0.3)
            .progressViewStyle(CustomCircularProgressViewStyle(lineWidth: 4))
            .frame(height: 18)
            .padding(.trailing, 10)
          Text("Today")
              .foregroundColor(.white)
              .font(.system(size: 15, weight: .bold, design: .rounded))
          Spacer()
          Image("left-arrow")
            .foregroundColor(.white.opacity(0.2))
          Rectangle().frame(width: 10, height: 0)
          Image("right-arrow")
            .foregroundColor(.white.opacity(0.2))
        }.padding(.horizontal, 14)
      }.frame(height: 42)
      Rectangle()
        .fill(
            LinearGradient(
              gradient: Gradient(colors: [Color(hex: 0x191919).opacity(0.8), Color(hex: 0x191919).opacity(0)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .frame(height: 6)
      Line()
         .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
         .frame(height: 2)
         .foregroundColor(Color(hex: 0x3C3B40))
      
    }
  }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}


struct TasksView: View {
  let exampleTasks: [Task] = [
    Task(
        title: "Task 1",
        description: "Description 1",
        dueDate: "2024-08-09T20:23:18.768Z", // Due later today at 6:00 PM
        priority: 1,
        isComplete: false
    ),
]
  
  var body: some View {
    VStack {
      TaskView(task: exampleTasks[0])
    }.padding(.top, 50)
      .padding(.leading, 14)
      .padding(.trailing, 8)
  }
}

struct TaskView: View {
  var task: Task
  
  let priorityColors: [Color] = [
    Color(hex: 0xFF645E),
    Color(hex: 0xFF8F24),
    Color(hex: 0x4A8CFC),
    Color(hex: 0x525252),
  ]
  
  func getPrimaryColor() -> Color {
    if task.priority > 4 || task.priority < 0 {
      return priorityColors[3]
    } else {
      return priorityColors[task.priority - 1]
    }
  }
  
  var body: some View {
    HStack (alignment: .top, spacing: 10) {
      Circle()
        .fill(getPrimaryColor().opacity(0.15))
        .frame(width: 20, height: 20)
        .overlay(
          Circle()
            .strokeBorder(getPrimaryColor(), lineWidth: 2.5)
        )
        .padding(.top, 3)
        .onTapGesture {
          print("Circle button tapped!")
        }
      VStack (alignment: .leading, spacing: 2) {
        Text(task.title)
          .foregroundColor(.white)
          .font(.system(size: 14, weight: .regular, design: .rounded))
          .lineLimit(1)
          .truncationMode(.tail)
        DataView(task: task)
      }
      Spacer()
    }.padding(.vertical, 6)
  }
}

func extractTime(from iso8601String: String) -> String? {
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  let date = formatter.date(from: iso8601String)
  
  if date == nil {
    return "F"
  }
  
  let currentDate = Date()
  if currentDate < date! { // Do not show if date has passed (will be handled by overdue)
    return nil
  }
  
  let cal = Calendar.current
  let comps = cal.dateComponents([.hour, .minute, .second], from: date!)
  
  if (comps.hour == 0 && comps.minute == 0 && comps.second == 0) {
    return nil // Do not show if time is not included
  }
  
  let dateFormatter = DateFormatter()
  dateFormatter.dateFormat = "h:mm a"
  
  return dateFormatter.string(from: date!)
}

struct DataView: View {
  var task: Task
  
  private func showTime() -> some View  {
    
    if let timeString = extractTime(from: task.dueDate) {
      return AnyView(HStack (spacing: 4) {
        Text(timeString)
          .foregroundColor(Color(hex: 0x98989F))
          .font(.system(size: 13, weight: .regular, design: .rounded))
          .lineLimit(1)
          .truncationMode(.tail)
        Circle()
          .fill(Color(hex: 0xCFCFD1))
          .frame(width: 4, height: 4)
          .padding(.trailing, 6)
      })
    }
    
    return AnyView(Rectangle().frame(width: 0, height: 0))
  }
  
  var body: some View {
    HStack (spacing: 0) {
      showTime()
      Text(task.description)
        .foregroundColor(Color(hex: 0x98989F))
        .font(.system(size: 13, weight: .regular, design: .rounded))
        .lineLimit(1)
        .truncationMode(.tail)
    }
  }
}

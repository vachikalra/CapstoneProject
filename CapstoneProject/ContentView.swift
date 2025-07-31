import SwiftUI
import UserNotifications


struct MergedStudyBuddyView: View {
    enum Section: String, CaseIterable, Identifiable {
        case tasks = "Tasks"
        case wellness = "Wellness"
        case challenges = "Challenges"
        var id: String { self.rawValue }
    }

    @State private var selectedSection: Section? = nil
    @State private var tasks: [TaskItem] = []
    @State private var newTask = ""
    @State private var challengeInput = ""
    @State private var selectedGroup: String? = nil

    var body: some View {
        NavigationStack {
            if let section = selectedSection {
                ZStack {
                    Color(red: 0.933, green: 0.725, blue: 0.941)
                        .ignoresSafeArea()
                    VStack {
                        Button("← Back") {
                            selectedSection = nil
                        }
                        .foregroundColor(.blue)
                        .padding(.top)

                        switch section {
                        case .tasks:
                            taskView
                        case .wellness:
                            wellnessView
                        case .challenges:
                            challengeView
                        }
                    }
                    .padding()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Image("1")
                            .resizable()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .padding(.top, 50)
                    }
                }
            } else {
                ZStack {
                    Color(red: 0.933, green: 0.725, blue: 0.941)
                        .ignoresSafeArea()
                    VStack(spacing: 30) {
                        Image("1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        ForEach(Section.allCases) { section in
                            Button(action: {
                                selectedSection = section
                            }) {
                                Text(section.rawValue)
                                    .font(.title2)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .foregroundColor(.purple)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    var taskView: some View {
        VStack(spacing: 16) {
            Text("Choose a Task Category")
                .font(.title2)
                .bold()
                .padding(.top)

            HStack(spacing: 20) {
                Button("📚 Study") { addTask("Study for test") }
                Button("🧹 Chores") { addTask("Do chores") }
                Button("☕ Break") { addTask("Take a short break") }
            }
            .buttonStyle(.borderedProminent)

            Divider()

            List {
                ForEach(tasks) { task in
                    HStack {
                        Text(task.title)
                            .strikethrough(task.isCompleted)
                            .foregroundColor(task.isCompleted ? .gray : .black)
                        Spacer()
                        if !task.isCompleted {
                            Button(action: {
                                markTaskComplete(task)
                            }) {
                                Image(systemName: "checkmark.circle")
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    tasks.remove(atOffsets: indexSet)
                }
            }

            HStack {
                TextField("Enter a task...", text: $newTask)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Add") {
                    if !newTask.isEmpty {
                        addTask(newTask)
                        newTask = ""
                    }
                }
                .padding(.horizontal)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.bottom)
        }
    }

    var wellnessView: some View {
        VStack(spacing: 16) {
            Text("Choose Your Group").font(.title2).bold().padding()
            HStack(spacing: 20) {
                Button("Middle School") { selectedGroup = "Middle School" }
                Button("High School") { selectedGroup = "High School" }
                Button("College") { selectedGroup = "College" }
            }
            .buttonStyle(.borderedProminent)

            if let group = selectedGroup {
                adviceView(for: group)
            }
        }
    }

    func adviceView(for group: String) -> some View {
        let tips: [String]
        switch group {
        case "Middle School":
            tips = [
                "Take breaks when studying to avoid burnout.",
                "Talk to a trusted adult when you're feeling overwhelmed.",
                "Get at least 8-10 hours of sleep every night.",
                "Limit screen time before bed to improve sleep.",
                "Stay active, even 20 mins of movement helps mood."
            ]
        case "High School":
            tips = [
                "Don't compare yourself to others, your journey is unique.",
                "Balance school with things you love to avoid stress.",
                "Stay organized with planners or apps like StudyBuddy!",
                "Set small, realistic goals to avoid procrastination.",
                "Sleep is just as important as studying. Prioritize it."
            ]
        default:
            tips = [
                "Check in with yourself often, mental health matters.",
                "Don’t overcommit. Rest is productive too.",
                "Stay connected with friends or support groups.",
                "Create boundaries between school and rest time.",
                "Reach out for help if you’re struggling - you’re not alone."
            ]
        }

        return VStack(alignment: .leading, spacing: 8) {
            Text("Wellness Tips for \(group)").font(.title3).bold().padding(.top)
            ForEach(tips, id: \.self) { tip in
                Text("• \(tip)")
            }
        }.padding()
    }

    var challengeView: some View {
        VStack(spacing: 16) {
            Text("What do you want reminders for every few hours?")
                .font(.headline)
                .padding()

            TextField("e.g. Drink water", text: $challengeInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button("Add Reminder") {
                if !challengeInput.isEmpty {
                    let newChallenge = "⏰ \(challengeInput) Reminder (every 2 hrs)"
                    tasks.insert(TaskItem(title: newChallenge), at: 0)
                    scheduleRepeatingReminder(title: challengeInput)
                    challengeInput = ""
                }
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .onAppear {
            requestNotificationPermission()
        }
    }

    func addTask(_ title: String) {
        tasks.append(TaskItem(title: title))
    }

    func markTaskComplete(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                tasks.remove(at: index)
            }
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted {
                print("Permission granted")
            }
        }
    }

    func scheduleRepeatingReminder(title: String) {
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = title
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7200, repeats: true) // 2 hours
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}

struct TaskItem: Identifiable, Hashable {
    var id = UUID()
    var title: String
    var isCompleted = false
}

#Preview {
    MergedStudyBuddyView()
}


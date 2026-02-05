//
//  ContentView.swift
//  my_ios_calendar
//
//  Created by Zachary Grimaldi on 12/27/25.
//

import SwiftUI
import Combine

struct CalendarEvent: Identifiable, Codable {
    let id: UUID
    var title: String
    var date: Date
    var color: String
    
    init(id: UUID = UUID(), title: String, date: Date, color: String = "blue") {
        self.id = id
        self.title = title
        self.date = date
        self.color = color
    }
    
    var swiftUIColor: Color {
        switch color {
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
}

class EventStore: ObservableObject {
    @Published var events: [CalendarEvent] = []
    
    func events(for date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        return events.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func addEvent(_ event: CalendarEvent) {
        events.append(event)
    }
    
    func deleteEvent(_ event: CalendarEvent) {
        events.removeAll { $0.id == event.id }
    }
}

struct ContentView: View {
    @StateObject private var eventStore = EventStore()
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showingAddEvent = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CalendarHeader(currentMonth: $currentMonth)
                
                WeekdayHeader()
                
                CalendarGrid(
                    currentMonth: currentMonth,
                    selectedDate: $selectedDate,
                    eventStore: eventStore
                )
                
                Divider()
                    .padding(.top, 8)
                
                EventListView(
                    selectedDate: selectedDate,
                    eventStore: eventStore
                )
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddEvent = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Today") {
                        withAnimation {
                            currentMonth = Date()
                            selectedDate = Date()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView(eventStore: eventStore, selectedDate: selectedDate)
            }
        }
    }
}

struct CalendarHeader: View {
    @Binding var currentMonth: Date
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    var body: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text(monthYearString)
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    private func previousMonth() {
        withAnimation {
            currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation {
            currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
}

struct WeekdayHeader: View {
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
}

struct CalendarGrid: View {
    let currentMonth: Date
    @Binding var selectedDate: Date
    @ObservedObject var eventStore: EventStore
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    private var days: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        let startDate = monthFirstWeek.start
        var days: [Date?] = []
        var currentDate = startDate
        
        while days.count < 42 {
            if calendar.isDate(currentDate, equalTo: currentMonth, toGranularity: .month) {
                days.append(currentDate)
            } else if days.isEmpty || days.last != nil {
                days.append(nil)
            } else {
                break
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        while days.count < 35 && days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                if let date = date {
                    DayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        hasEvents: !eventStore.events(for: date).isEmpty
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDate = date
                        }
                    }
                } else {
                    Color.clear
                        .frame(height: 44)
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEvents: Bool
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 36, height: 36)
                } else if isToday {
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: 36, height: 36)
                }
                
                Text(dayNumber)
                    .font(.system(size: 16, weight: isToday || isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : (isToday ? .blue : .primary))
            }
            
            Circle()
                .fill(hasEvents ? Color.blue : Color.clear)
                .frame(width: 6, height: 6)
        }
        .frame(height: 44)
    }
}

struct EventListView: View {
    let selectedDate: Date
    @ObservedObject var eventStore: EventStore
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }
    
    private var eventsForSelectedDate: [CalendarEvent] {
        eventStore.events(for: selectedDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dateString)
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 12)
            
            if eventsForSelectedDate.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No events")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(eventsForSelectedDate) { event in
                            EventRow(event: event, onDelete: {
                                eventStore.deleteEvent(event)
                            })
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}

struct EventRow: View {
    let event: CalendarEvent
    let onDelete: () -> Void
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: event.date)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(event.swiftUIColor)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.body)
                    .fontWeight(.medium)
                Text(timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct AddEventView: View {
    @ObservedObject var eventStore: EventStore
    let selectedDate: Date
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var eventDate: Date
    @State private var selectedColor = "blue"
    
    private let colors = ["blue", "red", "green", "orange", "purple", "pink"]
    
    init(eventStore: EventStore, selectedDate: Date) {
        self.eventStore = eventStore
        self.selectedDate = selectedDate
        _eventDate = State(initialValue: selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Event title", text: $title)
                    DatePicker("Date & Time", selection: $eventDate)
                }
                
                Section("Color") {
                    HStack(spacing: 16) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(colorFromString(color))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let event = CalendarEvent(title: title, date: eventDate, color: selectedColor)
                        eventStore.addEvent(event)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func colorFromString(_ string: String) -> Color {
        switch string {
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
}

#Preview {
    ContentView()
}

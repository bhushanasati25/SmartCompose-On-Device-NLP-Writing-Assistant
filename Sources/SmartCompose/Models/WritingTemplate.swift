import Foundation

/// Pre-built writing templates for quick document scaffolding.
enum WritingTemplate: String, CaseIterable, Identifiable {
    case blank = "Blank"
    case email = "Email"
    case letter = "Formal Letter"
    case notes = "Meeting Notes"
    case essay = "Essay"
    case report = "Report"
    case proposal = "Proposal"

    var id: String { rawValue }

    /// SF Symbol icon for the template.
    var icon: String {
        switch self {
        case .blank: return "doc"
        case .email: return "envelope.fill"
        case .letter: return "text.page.fill"
        case .notes: return "list.bullet.clipboard.fill"
        case .essay: return "text.book.closed.fill"
        case .report: return "chart.bar.doc.horizontal.fill"
        case .proposal: return "doc.richtext.fill"
        }
    }

    /// Short description of the template.
    var subtitle: String {
        switch self {
        case .blank: return "Start from scratch"
        case .email: return "Professional email structure"
        case .letter: return "Business letter format"
        case .notes: return "Structured meeting notes"
        case .essay: return "Introduction, body, conclusion"
        case .report: return "Executive summary and findings"
        case .proposal: return "Problem, solution, timeline"
        }
    }

    /// The template body text.
    var content: String {
        switch self {
        case .blank:
            return ""

        case .email:
            return """
            Subject: 

            Dear [Recipient Name],

            I hope this email finds you well. I am writing to [purpose of the email].

            [Main content of the email - provide details, context, and any necessary information.]

            [If applicable, include any action items or next steps.]

            Please let me know if you have any questions or need further clarification.

            Best regards,
            [Your Name]
            """

        case .letter:
            return """
            [Your Name]
            [Your Address]
            [City, State ZIP]
            [Date]

            [Recipient Name]
            [Recipient Title]
            [Organization Name]
            [Address]
            [City, State ZIP]

            Dear [Recipient Name],

            I am writing to [state the purpose of the letter]. [Provide brief context or background.]

            [Body paragraph 1 - Main point or request.]

            [Body paragraph 2 - Supporting details or additional information.]

            [Body paragraph 3 - Any action items, deadlines, or follow-up steps.]

            Thank you for your time and consideration. I look forward to your response.

            Sincerely,
            [Your Name]
            [Your Title]
            """

        case .notes:
            return """
            Meeting Notes
            Date: [Date]
            Attendees: [Names]
            Location: [Location/Virtual]

            Agenda
            1. [Topic 1]
            2. [Topic 2]
            3. [Topic 3]

            Discussion Points
            - [Key discussion point 1]
            - [Key discussion point 2]
            - [Key discussion point 3]

            Decisions Made
            - [Decision 1]
            - [Decision 2]

            Action Items
            - [ ] [Task 1] — Owner: [Name] — Due: [Date]
            - [ ] [Task 2] — Owner: [Name] — Due: [Date]
            - [ ] [Task 3] — Owner: [Name] — Due: [Date]

            Next Meeting
            Date: [Date]
            Topics: [Planned topics]
            """

        case .essay:
            return """
            [Essay Title]

            Introduction
            [Hook - an engaging opening sentence or question.]
            [Background context - provide necessary information for the reader.]
            [Thesis statement - clearly state your main argument or position.]

            Body Paragraph 1
            [Topic sentence - introduce the first supporting point.]
            [Evidence and analysis - provide examples, data, or reasoning.]
            [Transition to next point.]

            Body Paragraph 2
            [Topic sentence - introduce the second supporting point.]
            [Evidence and analysis - provide examples, data, or reasoning.]
            [Transition to next point.]

            Body Paragraph 3
            [Topic sentence - introduce the third supporting point.]
            [Evidence and analysis - provide examples, data, or reasoning.]

            Conclusion
            [Restate thesis in light of the evidence presented.]
            [Summarize key points.]
            [Concluding thought - call to action, future implications, or final reflection.]
            """

        case .report:
            return """
            [Report Title]
            Prepared by: [Author Name]
            Date: [Date]

            Executive Summary
            [A brief overview of the report's purpose, key findings, and recommendations. This section should be concise enough to stand alone.]

            Background
            [Context and background information relevant to the report. What prompted this report? What problem or question is being addressed?]

            Methodology
            [How was the data collected or analysis performed? What tools or frameworks were used?]

            Findings
            1. [Finding 1 - Present data, observations, or results.]
            2. [Finding 2 - Present data, observations, or results.]
            3. [Finding 3 - Present data, observations, or results.]

            Analysis
            [Interpret the findings. What do they mean? What patterns or trends emerge?]

            Recommendations
            1. [Recommendation 1]
            2. [Recommendation 2]
            3. [Recommendation 3]

            Conclusion
            [Summarize the report and reinforce the most important recommendations.]

            Appendix
            [Any supporting data, charts, or additional documentation.]
            """

        case .proposal:
            return """
            [Proposal Title]
            Submitted by: [Your Name / Team]
            Date: [Date]

            Problem Statement
            [Clearly define the problem or opportunity being addressed. Why is this important?]

            Proposed Solution
            [Describe your proposed approach in detail. How does it address the problem?]

            Objectives
            1. [Objective 1]
            2. [Objective 2]
            3. [Objective 3]

            Scope
            [Define what is included and excluded from this proposal.]

            Timeline
            - Phase 1: [Description] — [Start Date] to [End Date]
            - Phase 2: [Description] — [Start Date] to [End Date]
            - Phase 3: [Description] — [Start Date] to [End Date]

            Budget
            [Provide a high-level budget breakdown if applicable.]

            Expected Outcomes
            [What are the expected results and how will success be measured?]

            Next Steps
            [What needs to happen to move forward with this proposal?]
            """
        }
    }

    /// Suggested title for the template.
    var suggestedTitle: String {
        switch self {
        case .blank: return "Untitled"
        case .email: return "New Email"
        case .letter: return "New Letter"
        case .notes: return "Meeting Notes"
        case .essay: return "New Essay"
        case .report: return "New Report"
        case .proposal: return "New Proposal"
        }
    }
}

//
//  SwiftUIView 2.swift
//
//
//  Created by Kris Steigerwald on 3/15/23.
//
import SwiftUI
import Combine

struct PreviewStruct: View {
    @State var index: Int = 0
    @State public var survey: Survey

    var body: some View {
        VStack {
            SurveyView(survey: $survey, index: $index)
        }
        .onChange(of: index, perform: { val in
            print(val)
        })
    }
}

public struct SurveyView: View {
    @Namespace private var namespace
    @State private var isAnimating = false
    @State public var surveyService: SurveyService

    // A single response that comes from a question
    @State var response: SurveyResponse = SurveyResponse()

    @Binding public var survey: Survey
    @Binding public var index: Int
    static let log = Logger("SurveyMakito")
    @State public var showAlert: Bool = false
    @State public var counter: Int = 0
    public init(
        surveyService: SurveyService = SurveyService(),
        survey: Binding<Survey>,
        index: Binding<Int>
    ) {
        self.surveyService = surveyService
        self._survey = survey
        self._index = index
    }

    func switchView(question: SurveyQuestion) -> some View {
        switch question.type {
        case .binaryChoice:
            return AnyView(BinaryQuestionView(question: question, response: $response))
        case .multipleChoiceQuestion:
            return AnyView(MultipleChoiceQuestionView(question: question, response: $response, isAnimating: $isAnimating))
        case .inlineQuestionGroup:
            return AnyView(InlineMultipleChoiceQuestionGroupView(question: question))
        case .contactForm:
            return AnyView(ContactFormQuestionView(question: question, response: $response))
        case .commentsForm:
            return AnyView(CommentsFormQuestionView(question: question))
        default:
            return AnyView(EmptyView())
        }
    }

    func stackToAnim(questions: [SurveyQuestion]) -> some View {
        AnyView(
            LazyVStack(spacing: 20) {
                if let questions = survey.questions {
                    if let question = questions[index] {
                        switchView(question: question)
                    }
                }
            }.padding()
        )
    }

    public var body: some View {
        SurveyWrap(color: .gray) {
            ScrollView {
                if isAnimating {
                    if let questions = survey.questions {
                        stackToAnim(questions: questions)
                            .matchedGeometryEffect(id: "survey", in: namespace)
                    }
                } else {
                    if let questions = survey.questions {
                        stackToAnim(questions: questions)
                            .matchedGeometryEffect(id: "survey", in: namespace)
                    }
                }
            }
        } footer: {
            VStack {
                Text("count: \(counter)")
                HStack {
                    if let questions = survey.questions {
                        SurveyNavigationFooterView(questions: questions, index: $index, isAnimating: $isAnimating)

                    }
                }
            }
        }
        .onChange(of: response) { _ in
            counter = surveyService.responses.keys.count
            do {
                try surveyService.addResponse(response: response)
                surveyService.log()
            } catch {
                showAlert = true
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Fatal Error"),
                message: Text("Important data missing" +
                                "determined at this time.")
            )
        }
        .navigationBarTitle("Survey", displayMode: .inline)
    }
}

struct SurveyView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewStruct.preview
            .environmentObject(SurveyService())
    }
}

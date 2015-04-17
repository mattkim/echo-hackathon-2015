require 'text'

class JeopardyController < ApplicationController
    @@memory = {}
    
    skip_before_filter :verify_authenticity_token
    
    # GET /
    def show
        file = File.read('alexa-hackday-ten-questions-clean.json')
        trivia_questions = JSON.load(file)
    
        render json: trivia_questions.sample
    end
    
    # GET /
    def index
        @file = File.read('alexa-hackday-ten-questions-clean.json')
        @trivia_questions = JSON.load(@file)
    
        render json: @trivia_questions
    end
    
    def handleAnswer(actual_answer, user_answer)
        is_correct = is_answer_correct_fuzzy(user_answer, actual_answer)
        correctness_string = ""
        if is_correct
            correctness_string = "#{actual_answer} is right! You're Awesome!"
        else
            correctness_string = "#{user_answer} is wrong. You wanted #{actual_answer}!"
        end


        response = {
            version: "1.0",
            sessionAttributes: {
            },
            response: {
                outputSpeech: {
                    type: "PlainText",
                    text: correctness_string
                },
                card: { 
                    type: "Simple",
                    title: "Alexa Hackday - Jeopardy",
                    subtitle: "Credits:",
                    content: "robepyke, mattkim, ameirele"
                },
                shouldEndSession: true
            }
        }
        
        return response
    end
    
    # POST /
    def create
        
        
        session = params["session"] || {}
        session_id = session["sessionId"]
        request = params["request"] || {}
        request_id = request["requestId"]
        session_new = session["new"]
        intent = request["intent"] || {}
        slots = intent["slots"] || {}
        answer_slot = slots["answer"] || {}
        
        puts slots.inspect
        user_answer = answer_slot["value"] || ""
        
        attributes = session["attributes"] || {}
        question_id = attributes["question_index"].to_i
        puts "QUESTION ID: #{question_id}"
        question = get_question_by_index(question_id)
        actual_answer = question["answer"]
        
        
        puts "USER: #{user_answer}"
        puts "ACTUAL: #{actual_answer}"
        
        if @@memory[session_id] and @@memory[session_id]["prev_state"] == "question_asked"
            response = handleAnswer(actual_answer, user_answer)
        else
            @@memory[session_id] = {"prev_state" => "question_asked"}
       
            question, question_index = get_random_question()
            
            response = 
            {
                version: "1.0",
                sessionAttributes: {
                    question_index: question_index
                },
                response: {
                    outputSpeech: {
                        type: "PlainText",
                        text: "For #{question['value']}, #{question['question']}"
                    },
                    card: {
                        type: "Simple",
                        title: "Alexa Hackday - Jeopardy",
                        subtitle: "Credits:",
                        content: "robepyke, mattkim, ameirele"
                    },
                    shouldEndSession: false
                }
            }
        end

        puts params.inspect
        
        render json: response
    end
    
    def get_random_question
        questions = get_questions()
        
        lower_bound = 0
        upper_bound = questions.size - 1
        
        random_index = Random.new.rand(lower_bound..upper_bound)
        random_question = get_question_by_index(random_index)
        
        return random_question, random_index
    end
    
    def get_answer_to_question(question_index)
        question = get_question_by_index(question_index)
        answer = question[:answer]
    end
    
    def get_questions
        file = File.read('alexa-hackday-ten-questions-clean.json')
        trivia_questions = JSON.load(file)
        return trivia_questions
    end
    
    def get_question_by_index(index)
        questions = get_questions()
        return questions[index]
    end
    
    def is_answer_correct(user_answer, correct_answer)
        #minimum_distance = correct_answer.length/4
        #distance = Text::Levenshtein.distance(user_answer, correct_answer)
        #return distance < minimum_distance
        
        
        return user_answer.downcase == correct_answer.downcase 
    end
    
    def is_answer_correct_fuzzy(user_answer, correct_answer)
        
        minimum_distance = correct_answer.length/4
        distance = levenshtein(user_answer.downcase, correct_answer.downcase)
        
        puts "Distance: #{distance}"
        
        return distance < minimum_distance
    end
    
    def levenshtein(first, second)
    matrix = [(0..first.length).to_a]
    (1..second.length).each do |j|
    matrix << [j] + [0] * (first.length)
    end
    
    (1..second.length).each do |i|
    (1..first.length).each do |j|
      if first[j-1] == second[i-1]
        matrix[i][j] = matrix[i-1][j-1]
      else
        matrix[i][j] = [
          matrix[i-1][j],
          matrix[i][j-1],
          matrix[i-1][j-1],
        ].min + 1
      end
    end
    end
    return matrix.last.last
    end
    
end

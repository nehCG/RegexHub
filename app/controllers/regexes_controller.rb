class RegexesController < ApplicationController
    def index
        @regexes = Regex.all
    end
  
    def show
        id = params[:id] # retrieve regex ID from URI route
        @regex = Regex.find(id) # look up regex by unique ID
        # will render app/views/regexs/show.<extension> by default
        @regex_input = params[:text].nil?? nil: params[:text][:content]
        @validity = Regex.check_integrity(@regex.expression,@regex_input)
        @testcases = Testcase.where(:regex_id => id)
        if params[:commit] == "Add to testcase"
            if @validity == 'No input.'
                #
            elsif @validity == 'No match!'
                flash[:notice] = "Testcase successfully added!"
                Testcase.create(regex_id:@regex.id,content:params[:text][:content],match:'false')
            elsif @validity == 'Matches!'
                flash[:notice] = "Testcase successfully added!"
                Testcase.create(regex_id:@regex.id,content:params[:text][:content],match:'true')
            end
            render :action => 'show'
            
        end

    end
    
    def new
        @regex = Regex.new
        @regex.testcases.build
        # @regex.testcases.build
        # @regex.testcases.build
    end

    def create

        # @regex = Regex.create!(regex_params)
        @regex = Regex.new(regex_params)
        if params[:add_testcase]
            # add empty ingredient associated with @recipe
            @regex.testcases.build
        elsif params[:remove_testcase]
            # nested model that have _destroy attribute = 1 automatically deleted by rails
            if @regex.testcases.first.nil?
                @regex.testcases.build
                flash[:notice] = "Must have at least one testcase!"
            end
        else
            # ready to submit, but have to do check first.
            #@regex.save
            #puts @regex.errors.full_messages.to_sentence
            #puts 'error message here'
            #    flash[:notice] = @regex.errors.messages.map { |k,v| v }.join('<br>').html_safe
            # params[:remove_testcase]

            testcase_error_flag = false
            error_msg = []
            if !params[:regex][:testcases_attributes].nil?
                params[:regex][:testcases_attributes].each do |k,v|
                    if !(v[:match].nil? || v[:content].nil?)
                        exp = @regex.expression
                        str = v[:content]
                        expect_res = v[:match] == 'true'? 'Matches!' : 'No match!'
                        if Regex.check_integrity(exp, str) != expect_res
                            #@regex.errors.add(:base, message: "Regex No.#{k} does not behave as expected.")
                            # @regex.errors[:base] <<  "Regex No.#{k} does not behave as expected."
                            error_msg.push("Regex No.#{k.to_i+1} does not behave as expected.")
                            #puts "Regex No.#{k} does not behave as expected."
                            testcase_error_flag = true
                            #puts @regex.errors.messages.map { |k,v| v }.join('<br>') 
                        end
                    end
                end
            end
            #puts @regex.errors.messages.map { |k,v| v }.join('<br>')

            if !(@regex.valid? & !testcase_error_flag)
                all_msg = error_msg + @regex.errors.messages.map { |k,v| v }
                flash[:notice] = all_msg.join('<br>').html_safe   
            else
                @regex.save
                flash[:notice] = "#{@regex.title} was successfully created."
                redirect_to regexes_path and return
            end
        end
        puts params
        render :action => 'new'
    end

    def destroy
        @regex = Regex.find(params[:id])
        @regex.destroy
        flash[:notice] = "Regex '#{@regex.title}' deleted."
        redirect_to regexes_path
    end

    private
    # Making "internal" methods private is not required, but is a common practice.
    # This helps make clear which methods respond to requests, and which ones do not.
    def regex_params
        params.require(:regex).permit(:title, :expression, :description, :tag, :created_at, testcases_attributes: [:content, :match,:_destroy])
    end
end
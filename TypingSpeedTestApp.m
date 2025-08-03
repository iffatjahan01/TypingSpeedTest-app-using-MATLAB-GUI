classdef TypingSpeedTestApp<matlab.apps.AppBase
    properties (Access=public)
        UIFigure        matlab.ui.Figure
        lblTitle        matlab.ui.control.Label
        lblChooseTest   matlab.ui.control.Label
        btnTimeTest     matlab.ui.control.Button
        btnWordTest     matlab.ui.control.Button
        btnCustomTest   matlab.ui.control.Button
        txtArea         matlab.ui.control.TextArea
        btnSaveResults  matlab.ui.control.Button
        lblInputText    matlab.ui.control.Label
        inputTextArea   matlab.ui.control.TextArea
        btnSubmitInput  matlab.ui.control.Button
        UIAxes          matlab.ui.control.UIAxes
    end
    properties (Access=private)
        test      cell
        results        struct 
        currentTest    struct 
    end
    
    methods (Access=private)
       
        
        function startTimeTest(app)  
            app.txtArea.Value={'TIME TEST OPTION:','1. 30 seconds','2. 1 minute'};
            tchoice= uiconfirm(app.UIFigure,'Choose your desired test:','Time Test','Options',{'30 seconds','1 minute'});
            switch tchoice
                case '30 seconds'
                    duration=30;
                case '1 minute'
                    duration=60;
            end
            numWordsRequested=duration*2; 
            randomwords=app.test(randperm(numel(app.test),numWordsRequested));
            app.txtArea.Value=[{'Type these words:'},strjoin(randomwords,' ')];
            app.currentTest.words=randomwords;
            app.currentTest.duration=duration;
            app.inputTextArea.Value='';
            app.lblInputText.Enable='on';
            app.inputTextArea.Enable='on';
            app.btnSubmitInput.Enable='on';
            t = timer('StartDelay',duration,'TimerFcn',@(~,~) uialert(app.UIFigure,'Times out!','Time is up'));
            start(t);
            tic;
        end

        function startWordTest(app)
            app.txtArea.Value={'WORD TEST OPTION:','1. 10 words','2. 25 words','3. 50 words'};
            wordchoice=uiconfirm(app.UIFigure,'Choose your desired test:','Word Test','Options',{'10 words','25 words','50 words'});
            switch wordchoice
                case '10 words'
                    numWords=10;
                case '25 words'
                    numWords=25;
                case '50 words'
                    numWords=50;
            end
            numWordsRequested=numWords;
            randomwords=app.test(randperm(numel(app.test),numWordsRequested));
            app.txtArea.Value=[{'Type these words:'},strjoin(randomwords,' ')];
            app.currentTest.words=randomwords;
            app.currentTest.numWords=numWords;
            app.inputTextArea.Value='';
            app.lblInputText.Enable='on';
            app.inputTextArea.Enable='on';
            app.btnSubmitInput.Enable='on';
            tic;
        end

function startCustomTest(app) 
    app.txtArea.Value='Enter your customized text:';
    app.currentTest.custom=true;
    app.inputTextArea.Value='';
    app.inputTextArea.Visible='on';
    app.btnSubmitInput.Visible='on';
    prompt={'Enter your custom text:'}; 
    dlgtitle='Custom Test';
    dims=[1 200];
    answer=inputdlg(prompt,dlgtitle,dims);
    if ~isempty(answer)
        customText=answer{1};
        app.txtArea.Value={'Type this custom text:',customText};
        app.currentTest.customText=customText;
    end
   
    app.lblInputText.Enable='on'; 
    app.inputTextArea.Enable='on';
    app.btnSubmitInput.Enable='on';
    tic;
end

function submitInput(app)
    elapsedTime=toc;
    typed=char(app.inputTextArea.Value);  
    typedWords=strsplit(typed,' ');

    if isfield(app.currentTest,'custom')
        targetWords=strsplit(app.currentTest.customText,' '); 
    else
        targetWords=app.currentTest.words;
    end

    Correct=sum(ismember(typedWords,targetWords));
    Incorrect=length(typedWords)-Correct;
    wpm=(Correct/elapsedTime)*60;
    accuracy=(Correct/numel(targetWords))*100;

    app.results.CorrectWords=Correct;
    app.results.IncorrectWords=Incorrect;
    app.results.WPM=wpm;
    app.results.Accuracy=accuracy;

    app.txtArea.Value=[{'Correct words: ',num2str(Correct)},{'Incorrect words: ',num2str(Incorrect)},{'Accuracy: ', num2str(accuracy),'%'},{'Words per minute (WPM): ',num2str(wpm)}];
    app.btnSaveResults.Enable='on';

    tinterval=linspace(0,elapsedTime,numel(typedWords));
    wpmD=zeros(size(tinterval));
    errorD=zeros(size(tinterval));
    for i=1:length(tinterval)
        currentTyped=typedWords(1:i);
        Correct=sum(ismember(currentTyped,targetWords(1:i)));
        wpmD(i)=(Correct/tinterval(i))*60;
        errorD(i)=~ismember(typedWords{i},targetWords);  
    end

    timefine=linspace(0,elapsedTime,10*numel(typedWords)); 
    wpmfine=interp1(tinterval,wpmD,timefine,'pchip');

    yyaxis(app.UIAxes,'left');
    plot(app.UIAxes,timefine,wpmfine,'LineWidth',3,'Color','#FFA500'); 
    xlabel(app.UIAxes,'Time (seconds)');
    ylabel(app.UIAxes,'Words per Minute (WPM)');
    title(app.UIAxes,'WPM vs TIME');
    grid(app.UIAxes,'on');

    yyaxis(app.UIAxes,'right');
    scatter(app.UIAxes,tinterval(errorD==1),ones(1,sum(errorD)),'r','x','LineWidth',2);
    ylim(app.UIAxes,[0 1]); 
    ylabel(app.UIAxes,'Errors');

    app.lblInputText.Enable='off'; 
    app.inputTextArea.Enable='off';
    app.btnSubmitInput.Enable='off';
end

        function saveResults(app)
            [file,path]=uiputfile('*.txt','Save Results As');
            if isequal(file,0)
                disp('User selected Cancel');
            else
                filename=fullfile(path,file);
                fid=fopen(filename,'w');
                if fid==-1
                    error('Cannot open file for writing: %s',filename);
                end
                fprintf(fid,'Typing Speed Test Results\n');
                fprintf(fid,'Correct words: %d\n',app.results.CorrectWords);
                fprintf(fid,'Incorrect words: %d\n',app.results.IncorrectWords);
                fprintf(fid,'Accuracy: %.2f%%\n',app.results.Accuracy);
                fprintf(fid,'Words per minute (WPM): %.2f\n', app.results.WPM);
                fclose(fid);
                uialert(app.UIFigure,'Results saved successfully!','Success');
            end
        end
    end

    methods (Access=public) 
        function app=TypingSpeedTestApp 

            createComponents(app) 
            app.test={'great' 'even' 'into' 'eye' 'so' 'home' 'they' 'new' 'ask' 'day' 'into' 'from' 'thing' 'against' 'get' 'because' 'down' 'she' 'seem' 'into' 'if' 'set' 'under' 'say' 'open' 'other' 'great' 'about' 'eye' 'how' 'so' 'home' 'become' 'leave' 'form' 'right' 'this' 'which' 'he' 'school' 'few' 'day' 'will' 'lead' 'where' 'first' 'plan' 'think' 'between' 'with' 'own' 'more' 'while' 'public' 'do' 'see' 'man' 'during' 'word' 'also' 'way' 'number' 'life' 'great' 'even' 'over' 'line' 'be' 'when' 'do' 'or' 'much' 'however' 'this' 'but' 'use' 'increase' 'one' 'come' 'high' 'own' 'person' 'however' 'come' 'must' 'down' 'even' 'person' 'lead' 'stand' 'move' 'again' 'increase' 'change' 'she' 'year' 'here' 'during' 'time' 'long' 'might' 'state' 'what' 'between' 'early' 'both' 'right' 'old' 'must' 'develop' 'person' 'look' 'long' 'large' 'then' 'into' 'early' 'house' 'present' 'these' 'little' 'many' 'as' 'order' 'what' 'eye' 'life' 'fact' 'set' 'like' 'how' 'we' 'those' 'point' 'school' 'over' 'tell' 'child' 'do' 'they' 'under' 'he' 'more' 'very' 'want' 'same' 'of' 'consider' 'look' 'must' 'think' 'people' 'come' 'part' 'open' 'place' 'be' 'also' 'show' 'get' 'be' 'very' 'not' 'large' 'of' 'same' 'little' 'out' 'he' 'so' 'old' 'plan' 'into' 'many' 'too' 'same' 'seem' 'each' 'point' 'turn' 'because' 'own' 'to' 'problem' 'develop' 'now' 'school' 'we' 'plan' 'another' 'to' 'also' 'both' 'just' 'hand' 'stand' 'but' 'they' 'hand' 'He' 'very' 'now' 'get' 'here' 'very' 'show' 'some' 'move' 'use' 'many' 'keep' 'work' 'order' 'again' 'off' 'many' 'ask' 'not' 'should' 'the' 'of' 'from' 'school' 'see' 'also' 'open' 'give' 'leave' 'never' 'tell' 'become' 'most' 'all' 'he' 'work' 'but' 'one' 'consider' 'before' 'no' 'between' 'order' 'possible' 'even' 'out' 'see' 'most' 'people' 'follow' 'the' 'program' 'leave' 'first' 'day' 'order' 'up' 'set' 'they' 'present' 'eye' 'another' 'consider' 'word' 'form' 'he' 'leave' 'while' 'this' 'child' 'leave' 'house' 'high' 'he' 'however' 'just' 'people' 'and' 'state' 'program' 'call' 'could' 'because' 'they' 'see' 'come' 'great' 'thing' 'leave' 'such' 'fact' 'little' 'since' 'begin' 'which' 'on' 'look' 'point'};

            app.results=struct('CorrectWords', 0, 'IncorrectWords', 0, 'Accuracy', 0, 'WPM', 0);
            app.currentTest=struct();
        end

        function delete(app) 
            delete(app.UIFigure)
        end
    end
end

function createComponents(app)

    
    app.UIFigure=uifigure('Visible', 'off');
    app.UIFigure.Position=[10, 5, 1200, 790];
    app.UIFigure.Name='TYPING SPEED TEST';
    app.UIFigure.Color='#373737'; 

    app.lblChooseTest=uilabel(app.UIFigure);
    app.lblChooseTest.Position=[32, 400, 150, 30];
    app.lblChooseTest.Text='CHOOSE TEST';
    app.lblChooseTest.FontSize=18;
    app.lblChooseTest.FontColor='w';

    app.btnTimeTest=uibutton(app.UIFigure,'push');
    app.btnTimeTest.Position=[20, 350, 150, 30];
    app.btnTimeTest.Text='TIME TEST';
    app.btnTimeTest.ButtonPushedFcn=@(btn,event) startTimeTest(app);
    app.btnTimeTest.BackgroundColor=[0.25, 0.25, 0.25];
    app.btnTimeTest.FontColor='w'; 

    app.btnWordTest=uibutton(app.UIFigure,'push');
    app.btnWordTest.Position=[20, 310, 150, 30];
    app.btnWordTest.Text='WORD TEST';
    app.btnWordTest.ButtonPushedFcn=@(btn,event) startWordTest(app);
    app.btnWordTest.BackgroundColor=[0.25, 0.25, 0.25]; 
    app.btnWordTest.FontColor='w';

    app.btnCustomTest=uibutton(app.UIFigure,'push');
    app.btnCustomTest.Position=[20, 270, 150, 30];
    app.btnCustomTest.Text='CUSTOM TEST';
    app.btnCustomTest.ButtonPushedFcn=@(btn,event) startCustomTest(app);
    app.btnCustomTest.BackgroundColor=[0.25, 0.25, 0.25]; 
    app.btnCustomTest.FontColor='w'; 

    app.txtArea=uitextarea(app.UIFigure);
    app.txtArea.Editable='off';
    app.txtArea.Position=[200, 500, 940, 280];
    app.txtArea.FontSize=13;
    app.txtArea.BackgroundColor=[0.25, 0.25, 0.25];
    app.txtArea.FontColor='w'; 
  
    app.lblInputText=uilabel(app.UIFigure);
    app.lblInputText.Position=[200, 455, 150, 30];
    app.lblInputText.Text='INSERT TEXT HERE';
    app.lblInputText.FontSize= 14;
    app.lblInputText.FontColor='w'; 
    app.lblInputText.Enable='off';

    app.inputTextArea=uitextarea(app.UIFigure);
    app.inputTextArea.Position=[200, 360, 940, 100];
    app.inputTextArea.FontSize= 13;
    app.inputTextArea.BackgroundColor=[0.25, 0.25, 0.25]; 
    app.inputTextArea.FontColor='w';
    app.inputTextArea.Enable='off';

    app.btnSubmitInput=uibutton(app.UIFigure,'push');
    app.btnSubmitInput.Position=[990, 325, 150, 30];
    app.btnSubmitInput.Text='Submit';
    app.btnSubmitInput.ButtonPushedFcn= @(btn,event) submitInput(app);
    app.btnSubmitInput.BackgroundColor=[0.25, 0.25, 0.25];
    app.btnSubmitInput.FontColor='w'; 
    app.btnSubmitInput.Enable='off';

    app.btnSaveResults=uibutton(app.UIFigure,'push');
    app.btnSaveResults.Position=[20, 230, 150, 30];
    app.btnSaveResults.Text='SAVE RESULT';
    app.btnSaveResults.ButtonPushedFcn= @(btn,event) saveResults(app);
    app.btnSaveResults.Enable='off';
    app.btnSaveResults.BackgroundColor=[0.25, 0.25, 0.25];
    app.btnSaveResults.FontColor='w'; 

    app.UIAxes=uiaxes(app.UIFigure);
    app.UIAxes.Position=[200, 20, 950, 300];
    title(app.UIAxes,'WPM vs TIME','Color','#FFE400'); 
    xlabel(app.UIAxes,'Time (seconds)','Color','w');
    ylabel(app.UIAxes,'Words per Minute (WPM)','Color','w'); 
    app.UIAxes.XColor='#00FFFB'; 
    app.UIAxes.YColor='#FF0000';
    app.UIAxes.Color=[0.15, 0.15, 0.15]; 
    grid(app.UIAxes,'on');

    app.UIFigure.Visible='on';  

end

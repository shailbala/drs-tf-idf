path = '/home/iota/Documents/MATLAB/DRS/';
filenames = ["biology1.txt" "biology2.txt" "chemistry1.txt" "chemistry2.txt" "Math1.txt" "Math2.txt" "OS1.txt" "OS2.txt"];
N = size(filenames, 2);

% find max length of words among all docs
maxWordLength = max(getWordLength(filenames, path));
% create a matrix this size to store all document-terms
% using padding
docMatrix = strings(maxWordLength, N);
wordLength = zeros(1,N);

%% ::::::::::::::::::::::::Read Documents::::::::::::::::::::::::
for i=1:size(filenames,2)
    filename = filenames(i);
    filePath = strcat(path, filename);
    fPointer = fopen(filePath, 'r');
    file = fscanf(fPointer,'%c');
    % all preprocessing
    words = preprocess(file);
    wordLength(i) = size(words, 2);
    % add words to docMatrix for ith doc
    docMatrix(1:wordLength(i), i) = words;
    %disp('reading document, value of i');
    %i
end

% ::::::::::::::::::::::::Calculate TF and IDF::::::::::::::::::::::::
[TF, termsVector] = getTF(docMatrix);
% another function to do the same thing
%[TF2, termsVector2] = getTF2(docMatrix, wordLength);
IDF = getIDF(TF);

disp('Preprocessing done!');
% read as string
query = input('Enter query term:', 's');
%query = "os";  % not found in any file
%query = "cell tissue";
%query = "mathematical covalent";
% preprocess query
qWords = preprocess(query);

% to calculate average tf-idf score for each doc
avgScore = zeros(1,N);
n = 0;
% get term index for each term and then its TF-IDF score
for i=1:size(qWords,2)
    term = qWords(i);
    index = find(termsVector == term);
    % in case term not found
    if size(index,1) == 0
        continue;
    end
    avgScore = avgScore + getTermScore(TF, IDF, index);
    n = n+1;
end

% do average
avgScore = avgScore./n;
% get document indices based on average tf-idf score
% in descending order
[out, idx] = sort(avgScore, 'descend');
n = input('Enter no. of doc-recommendation to show (1-8)');
%n = 3;
disp('Query:');
disp(query);
disp('Document Recommendations:');
for i=1:n
    % if the searched query words are not found
    % it will display all documents in series
    % print a statement none found
    if size(idx,1) == 0
        % no query word found
        %disp('Error: The query did not match anything!');
        disp(filenames(i));
        break;
    end
    disp(filenames(idx(i)));
end

%% ::::::::::::::::::::::::functions::::::::::::::::::::::::

function words = preprocess(str)
% split into words, convert into lowercase
% TODO: stopword removal etc.
    str = lower(str);
    % split into words
    words = strsplit(str);
end

% find total length of words in all docs
function wordLengths = getWordLength(filenames, path)
% returns the maximum length of words present among all documents
    wordLengths = zeros(1, size(filenames,2));
    for i=1:size(filenames,2)
        filename = filenames(i);
        % read each document
        filePath = strcat(path, filename);
        fPointer = fopen(filePath, 'r');
        file = fscanf(fPointer,'%c');
        % split words
        words = strsplit(file);
        % size of ith document
        wordLengths(i) = size(words,2);
    end
end

% test case
%{
% from GeeksForGeeks example
tf = [1 0 0;1 0 0;2 0 0;1 0 0;0 1 0;0 1 0;0 1 0;0 1 0;0 0 1;0 0 1;0 0 1;0 0 1;0 0 1;];
d = [7 5 6];
%}

function normalizedTF = normalize(TF, docLength)
% normalize each item using formula
% (term_t, doc_i) = TF(t,i)/docLength(i)
normalizedTF = TF./docLength;
end

function freq = getTermFreq(term, docMatrix)
    freq = sum(docMatrix == term);
end

% get TF
function [TF, termsVector] = getTF(docMatrix)
% takes a vector of documents and their size (in words)
% returns:
%   1) term frequency matrix, TF
% each row represents a term, each column a document in the
% same order as filenames
%   2) termsVector
% vector of all unique terms in all documents
% TF has terms in same order
    N = size(docMatrix,2);  % number of documents
    % find all unique terms (in alphabetically sorted order)
    termsVector = unique(docMatrix);
    % remove padding "", 1st element
    termsVector(1) = [];
    
    TF = zeros(size(termsVector,1),N);
    
    % iterate through all unique terms
    % find frequency count for each term in each doc
    for i=1:size(termsVector,1)
        term = termsVector(i);
        TF(i,:) = getTermFreq(term, docMatrix);
    end
end

% ==================another implementation==================
% output matches with getTF() implementation, except order
% get TF
function [TF, termsVector] = getTF2(docMatrix, docLength)
% takes a vector of documents and their size (in words)
% returns:
%   1) term frequency matrix, TF
% each row represents a term, each column a document in the
% same order as filenames
%   2) termsVector
% vector of all unique terms in all documents
% TF has terms in same order
    N = size(docMatrix,2);  % number of documents
    % to store all unique terms
    % initialize with one word, otherwise logic won't work
    % line 110, checking for new word won't work
    termsVector = [""];
    
    TF = [];
    % iterate through all docs
    % for each new term, find its frequency
    % find frequency count for each term in each doc
    for i=1:N
        % find last word index, padding starts after it
        lastWordIndex = docLength(i);
        
        % get words for current doc
        doc_i = docMatrix(1:lastWordIndex,i);
        
        for i=1:size(doc_i)
            term = doc_i(i);
            % if new word
            if sum(term==termsVector) == 0
                termsVector = [termsVector;term];
                freq = getTermFreq(term, docMatrix);
                TF = [TF; freq];
            end
        end
    end
    % remove the extra "" added during intialization
    termsVector(1) = [];
end

% get TF
function [TFquery, termsVector] = getTFforQuery(query, docMatrix)
% takes a vector of documents and a query list of words
% returns:
%   1) term frequency matrix, TF
% each row represents a term, each column a document in the
% same order as filenames
%   2) termsVector
% vector of all unique terms in query
% TF has terms in same order
    N = size(docMatrix,2);  % number of documents
    % find all unique terms (in alphabetically sorted order)
    termsVector = unique(query);
    
    TFquery = zeros(size(termsVector,1),N);
    
    % iterate through all unique terms
    % find frequency count for each term in each doc
    for i=1:size(termsVector,1)
        term = termsVector(i);
        TFquery(i,:) = getTermFreq(term, docMatrix);
    end
end

function IDF = getIDF(TF)
% IDF(term_t) = log(N/No. of Doc with term_t in it)
    N = size(TF,2); % number of docs = number of columns in TF
    % ith row contains data of ith term
    % No.ofDocs with ith term = no.of non-zero items in TF in ith row
    nDocsWithTerm = N-sum(TF'==0);
    nDocsWithTerm = nDocsWithTerm';
    IDF = log2(N./nDocsWithTerm);
end

function tfIdfScore = getTermScore(TF, IDF, term_index)
    tfIdfScore = TF(term_index, :).*IDF(term_index);
end

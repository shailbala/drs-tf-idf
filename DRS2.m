path = '/home/iota/Documents/MATLAB/DRS/';
filenames = ["biology1.txt" "biology2.txt" "chemistry1.txt" "chemistry2.txt" "Math1.txt" "Math2.txt" "OS1.txt" "OS2.txt"];
N = size(filenames, 2);

% find max length of words among all docs
maxWordLength = max(getWordLength(filenames, path));
% create a matrix this size to store all document-terms
% using padding
docMatrix = strings(maxWordLength, N);
wordLength = zeros(1,N);

for i=1:size(filenames,2)
    filename = filenames(i);
    filePath = strcat(path, filename);
    fPointer = fopen(filePath, 'r');
    file = fscanf(fPointer,'%c');
    file = lower(file);
    % split into words
    words = strsplit(file);
    wordLength(i) = size(words, 2);
    % add words to docMatrix for ith doc
    docMatrix(1:wordLength(i), i) = words;
end

[TF, termsVector] = getTF(docMatrix, wordLength);
IDF = getIDF(TF);

disp('Preprocessing done!');
% read as string
query = lower(input('Enter query term:', 's'));
%query = "os";  % not found in any file
%query = "cell";

% to calculate average tf-idf score for each doc
avgScore = zeros(1,N);
% get term index for each term and then its TF-IDF score

index = find(termsVector == query);
% in case term not found
if size(index,1) ~= 0
    avgScore = avgScore + TF(index, :).*IDF(index);
end

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

% get TF
function [TF, termsVector] = getTF(docMatrix, docLength)
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
                freq = zeros(1,N);
                % find frequency
                for j=1:N
                    %j
                    % for jth doc
                    freq(j) = sum(term == docMatrix(:,j));
                end
                TF = [TF; freq];
            end
        end
    end
    % remove the extra "" added during intialization
    termsVector(1) = [];
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
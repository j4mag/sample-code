%This simulation compares various strategies for the Arknights clue game.
%   In this clue game, players try to maximize their credits.
%   Credits can be obtained in three ways. First: obtain clues enumerated 1-7,
%   obtaining 210 credits, at most once per day. Second: visit friends' parties,
%   obtaining 30 credits per friend, per day, at most 10 times per day.
%   Finally, credits are obtained both when giving and receiving clues 
%   (20 for giving, 15 for receiving).
%
%   The goal of this simulation is to determine which strategies perform optimally,
%   and if it is possible to construct a collaborative strategy that performs better
%   overall than a selfish strategy.
%
%   Results seem to indicate:
%       * Selfish strategies dominate
%       * Clues obtained by parties nearly always reach 300/day, regardless of strategy
%
%
%   Inputs:
%       p: an array of relative proportions for each player strategy:
%           [p_selfish, p_selfless, p_collab, p_hybrid, p_secretive, p_keepone]
%   Example:
%       ComparePlayers([0.5, 0.25, 0.125, 0.125, 0, 0])
%       ComparePlayers([100, 200, 200, 100, 10, 5])


function ComparePlayers(p)
p = p/sum(p);
N_Types = 6;
typeNames = ["Selfish  ","Selfless ","Collab   ","Hybrid   ","Secretive","KeepOne  "];
epsilon = 1e-8; %fudge-factor for division, used for statistical analysis.

N = 1000; % The total number of players
IDs = 1:N;
N_days = 100;
n_type = zeros(1,N_Types);
players = cell(1,N);
N_friends = 30;
 
% Create players, types assigned randomly, in proportion according to the array p.
for n = IDs
    r = rand;
    for type = 1:N_Types
        if r<=sum(p(1:type))
            n_type(type) = n_type(type)+1;
            switch type
                case 1
                    players{n} = SelfishPlayer(n);
                case 2
                    players{n} = SelflessPlayer(n);
                case 3
                    players{n} = CollabPlayer(n);
                case 4
                    players{n} = HybridPlayer(n);
                case 5
                    players{n} = SecretivePlayer(n);
                case 6
                    players{n} = KeepOnePlayer(n);
            end
            break
        end
    end
end
% Assign friendships for each player, randomly among players 
%   with remaining friend slots.
for n = IDs
    invalidFriends = [n, players{n}.friendList];
    otherIDs = setdiff(IDs,invalidFriends);
    otherIDs = otherIDs(randperm(N-length(invalidFriends))); 
    for m = otherIDs
        if length(players{m}.friendList) < N_friends &&...
           length(players{n}.friendList) < N_friends 
            players{n} = players{n}.addFriend(m);
            players{m} = players{m}.addFriend(n);
        end
    end
end

%{
% Check if everyone has maximal friends
friendcounts = zeros(1,N);
for n = IDs
    friendcounts(n) = length(players{n}.friendList);
end
disp(friendcounts)
pause;
%}
totCredit       = zeros(1,N_Types);
totParties      = zeros(1,N_Types);
totVisitCredit  = zeros(1,N_Types);
DaysPerSegment  = 25;
for day = 1:N_days
    for n = IDs
        players{n} = players{n}.newDay();
    end
    %we assume 3 clues per day for all players, this is an estimate.
    for iter = 1:3
        for n = IDs
            %fprintf('----DBG: ')
            [players, players{n}] = players{n}.findClue(randi(7),players);
            %fprintf('\n')
        end
    end
    for n = IDs %obtain credits via visiting friends
        totVisitCredit(players{n}.playertype)= ...
            totVisitCredit(players{n}.playertype) + players{n}.partyCreditsToday;
    end
    fprintf('End of day %3d (%2.0f%%):\n',day,100*day/N_days)
    if(mod(day,DaysPerSegment)==0)   
        for n = IDs
            totCredit(players{n}.playertype) = ...
                totCredit(players{n}.playertype) + players{n}.credits;
            totParties(players{n}.playertype)= ...
                totParties(players{n}.playertype)+ players{n}.partiesThrown;
        end
        meanCredit = totCredit./(n_type+epsilon);
        meanParties = totParties./(n_type+epsilon);
        meanVisitCredit = totVisitCredit./(n_type+epsilon)/DaysPerSegment;

        for type = 1:N_Types
            fprintf('%s avg : %9.1f credits, %5.1f parties, %5.1f visit credit\n',...
            typeNames(type),meanCredit(type),meanParties(type),meanVisitCredit(type))
        end
        disp('¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯')
        totCredit       = zeros(1,N_Types);
        totParties      = zeros(1,N_Types);
        totVisitCredit  = zeros(1,N_Types);
    end
end

%clearvars players
end
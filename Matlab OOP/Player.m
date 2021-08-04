classdef Player
    %PLAYER This is an abstract class describing a clue game player.
    %   A clue game player can add friends, obtain credits, visit clue parties,
    %   obtain clues both automatically and from friends, and can throw clue parties.
    %   A player can only hold 10 clues, have 30 friends, and clues obtained from friends
    %   decay after 10 days.
    
    properties (Constant)
        maxClues = 10;
        maxFriends = 30;
        clueDurability = 10;
    end
    properties
        ID;
        playertype;
        rxClues = zeros(1,7);
        myClues = zeros(1,7);
        friendList = zeros(1,0);
        credits = 0;
        partyCreditsToday = 0;
        partiesThrown = 0;
        clueTimers = cell(1,7);
    end
    
    methods      
        function obj = Player(id)
            %PLAYER Construct an instance of this class
            %   Detailed explanation goes here
            obj.ID = id;
        end
        
        function self = addFriend(self,id)
            %ADDFRIEND Adds a friend to this player
            if length(self.friendList) >= self.maxFriends
                error('Player:addFriend',...
                    'Player %d already has maxFriends',self.ID);
            end
            if any(self.friendList==id)
                error('Player:addFriend',...
                    'Player %d is already friends with player %d',self.ID,id);
            end
                
            self.friendList = [self.friendList id];
        end
        
        function self = addCredits(self,amt)
            self.credits = self.credits + amt;
        end
        
        function self = receivePartyCredits(self)
            if self.partyCreditsToday < 300
                self.partyCreditsToday = self.partyCreditsToday + 30;
                self.credits = self.credits + 30;
            end
        end
        
        function self = newDay(self)
            self.partyCreditsToday = 0;
            for iter = 1:7
                clueTimer = self.clueTimers{iter};
                clueTimer = clueTimer - ones(size(clueTimer));
                for jter = 1:sum(clueTimer==0)
                    self = self.removeClue(iter);
                end
            end
        end
        
        function [players, self] = throwParty(self,players)
            %we assume parties resolve instantly, i.e. everyone who can
            %visit does so, and the player begins setting up for their next
            %party immediately.
            %fprintf('----DBG: P%d Party!\n',self.ID)
            
            for cluenum = 1:7
                self = self.removeClue(cluenum);
            end
            self.partiesThrown = self.partiesThrown + 1;
            self.credits = self.credits + 210;
            for friendID = self.friendList
                players{friendID} = players{friendID}.receivePartyCredits();
            end
        end
        
        function CL = getClueList(self)
            CL = self.myClues + self.rxClues;
        end
        
        function isTradeable = checkClueTradeability(self,players)
            for friendID = self.friendList
                %how many trades are possible for each type of clue, i.e.
                %which clue should I trade to remove as many dupes as
                %possible?
                possibleTrades = ((players{friendID}.getClueList()==0) & (self.myClues>0));
                if any(possibleTrades)
                   isTradeable = true;
                   return
                end
            end
            isTradeable = false;
        end
        
        function self = removeClue(self,cluenum)
            if self.rxClues(cluenum) > 0
                self.rxClues(cluenum) = self.rxClues(cluenum) - 1;
                timer = self.clueTimers{cluenum};
                timer(1) = [];
                self.clueTimers{cluenum} = timer;
            elseif self.myClues(cluenum) > 0
                self.myClues(cluenum) = self.myClues(cluenum) - 1;
            else
                warning('P%d tried to remove C#, but they didn''t have any.',self.ID,cluenum)
            end
        end
    end
    
    methods (Abstract)
        [players, self] = findClue(self,cluenum,players)
        [players, self] = receiveClue(self,cluenum,players,id)
    end
end


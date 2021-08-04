classdef SelflessPlayer < Player
    %SELFLESSPLAYER This is an Arknights player that uses their clues
    %selflessly
    %   A selfless player trades all their clues whenever, only 
    %   using them when it triggers a party.
    
    methods
        function self = SelflessPlayer(id)
            %SELFLESSPLAYER Construct an instance of this class
            %   Inputs:
            %       id: a unique integer identifier for this player.
            self@Player(id)
            self.playertype = 2;
        end
        
        function [players, self] = findClue(self,cluenum,players)
            %FINDCLUE this player finds a clue themselves
            %   Inputs:
            %       cluenum: the clue number found (1-7)
            %       players: a cell array of all players in the game. 
            %                   Yeah yeah yeah, I know it's a bad solution.
            %                   It works. Deal with it.
            %   Outputs:
            %       self: an updated version of this player, after this
            %                   operation. Overwrite the player whenever 
            %                   you use this method.
            %       players: an updated version of the players structure.
            %                   again, make sure to overwrite it whenever
            %                   you use this method
            %   Example:
            %       players = {SelfishPlayer(1), SelfishPlayer(2),
            %       SelflessPlayer(3)};
            %       [players{3}, players] = players{3}.findClue(1,players); 
            
            %fprintf('P%d F%d | ',self.ID,cluenum)
            if sum(self.myClues) < self.maxClues
                self.myClues(cluenum) = self.myClues(cluenum)+1;
                
                if all(self.getClueList()>0)
                    [players, self] = self.throwParty(players);
                end
                
                while self.checkClueTradeability(players)
                    %give away whenever I can
                    [players, self] = self.giveClue(players);
                end
            else
                [players, self] = self.giveClue(players);                
                %error('Player:findClue',...
                %    'Player %d already has max Clues',self.ID);
            end
        end
        
        function [players, self] = receiveClue(self,cluenum,players,~)
            %RECEIVECLUE this player is given a clue by another player. This
            %varies from SelfishPlayer.findClue because the clue is added 
            %to a list of untradeable 'gifted' clues instead of their own.
            %   Inputs:
            %       cluenum: the clue number found (1-7)
            %       players: a cell array of all players in the game. 
            %                   Yeah yeah yeah, I know it's a bad solution.
            %                   It works. Deal with it.
            %   Outputs:
            %       self: an updated version of this player, after this
            %                   operation. Overwrite the player whenever 
            %                   you use this method.
            %       players: an updated version of the players structure.
            %                   again, make sure to overwrite it whenever
            %                   you use this method
            %   Example:
            %       players = {SelfishPlayer(1), SelfishPlayer(2),
            %       SelflessPlayer(3)};
            %       [players{1}, players] = players{1}.receiveClue(1,players); 
            
            %fprintf('P%d R%d | ',self.ID,cluenum)
            self.rxClues(cluenum) = self.rxClues(cluenum)+1;
            self.clueTimers{cluenum} = [self.clueTimers{cluenum} self.clueDurability];
            
            if all(self.getClueList())
                [players, self] = self.throwParty(players);
            end
        end
        
        function [players, self] = giveClue(self,players)
            %GIVECLUE this player gives a clue by another player. The clue
            %given is decided automatically by looking through the player's
            %friend list at the most impactful trades possible.
            %   Inputs:
            %       players: a cell array of all players in the game. 
            %                   Yeah yeah yeah, I know it's a bad solution.
            %                   It works. Deal with it.
            %   Outputs:
            %       self: an updated version of this player, after this
            %                   operation. Overwrite the player whenever 
            %                   you use this method.
            %       players: an updated version of the players structure.
            %                   again, make sure to overwrite it whenever
            %                   you use this method
            %   Example:
            %       players = {SelfishPlayer(1), SelfishPlayer(2),
            %       SelflessPlayer(3)};
            %       [players{1}, players] = players{1}.findClue(1,players); 
            %       [players{1}, players] = players{1}.giveClue(players); 
            
            minRemaining = 8;
            bestTrade = 0;
            tradeClue = 0;
            tradeID = 0;
            %Look through friends list to find the best trade possible:
            %   prioritizing players who are missing the fewest clues, then
            %   choosing among them by giving the clue the player has the
            %   most of.
            for friendID = self.friendList
                %how many trades are possible for each type of clue, i.e.
                %which clue should I trade to remove as many dupes as
                %possible?
                possibleTrades = ((players{friendID}.getClueList()==0) & (self.myClues>0))...
                                    .* self.getClueList();
                if any(possibleTrades)
                    if any(possibleTrades) && ...
                           sum(players{friendID}.getClueList()==0) < minRemaining
                        tradeID = friendID;
                        minRemaining = sum(players{friendID}.getClueList()==0);
                        [bestTrade, tradeClue] = max(possibleTrades);
                        
                    elseif sum(players{friendID}.getClueList()==0)==minRemaining...
                            && max(possibleTrades) > bestTrade
                        tradeID = friendID;
                        [bestTrade, tradeClue] = max(possibleTrades);
                    end
                end
            end
            
            if minRemaining == 8
                tradeID = self.friendList(1);
                [~, tradeClue] = max(self.myClues);
                
                fprintf('----DBG: P%d has no trades: C#%d -> P%d\n',...
                        self.ID,tradeClue,tradeID)
                
            end

            %fprintf('P%d->P%d C#%d | ',self.ID,tradeID,tradeClue)
            
            self.myClues(tradeClue) = self.myClues(tradeClue) - 1;
            [players, players{tradeID}] = players{tradeID}.receiveClue(tradeClue,players,self.ID);
            self.credits = self.credits + 20;
            players{tradeID}.credits = players{tradeID}.credits + 15;
        end
    end
end


---
title: "Optimizing Gin Hands"
date: 2021-02-19T05:05:59-05:00
excerpt: "A novel algorithm for optimal scores in Gin, Three Thirteen and more!"
hero: "/images/three-thirteen.jpg"
readingTime: 12
category: posts
authors:
 - "Verity Scheel"
draft: false
---

## Backstory
When we started adding card games to our repertoire, the first game we coded up was [Spades](https://en.wikipedia.org/wiki/Spades_(card_game)). A classic among our family and friends, I’ve played it many times with (and against) my brother. The rules are pretty straightforward, but the fun twists of strategy lie in the bidding and the game play: whether your hand is good or bad depends on how others are choosing to play, as much as the luck of the cards themselves!

The one part of it that was new to me was adapting it for different numbers of players. We’d traditionally only played it with four players, in teams of two, but it turns out there are rules for 2–6 players – and Alex had even coded the rules up with all of these variations, by the time I got there.

Alex quickly decided that the next game he wanted to add was a game called [Three Thirteen](https://en.wikipedia.org/wiki/Three_thirteen), and we played it as a family to try it out. I had never played it before, but it’s a variation on familiar Gin and Rummy style games, which involve grouping cards into matches, which are three or more of a kind or runs of three or more (and typically runs have to be of the same suit). The goal is, of course, to get a hand with no unmatched cards – and the first player to have zero points left unmatched in their hand gets to go out first, thereby gaining an edge in the scoring.

The basics of gameplay for Three thirteen are quite straightforward: the first round starts off with 3 cards, and for each round, you go around and can either take the top card off the discard pile or off the deck, and discard from the hand to maintain the same number of cards. A round ends when a player achieves a perfectly groupable hand after discarding, and then everyone gets a last chance before grouping up their hands and tallying the score of unmatched cards in their hand. The next round then begins, re-dealing and adding an additional card to each hand – until the last round, where each player has 13 cards.

So the actual coding of the gameplay was straightforward, since there are only a few actions each player can take. But how to ensure the rules were being followed, and players only went out when they had no points in hand?

For a while, we played lawlessly, relying on trust that users wouldn’t go out while they still had points left (as well as counting their points accurately). This actually worked suboptimally, not because we couldn’t trust each other, but because people accidentally hit the wrong button! Users also forgot or didn’t understand how to group their cards to achieve a low score.

So we set out to make sure these mistakes wouldn’t happen.

-----

## The Challenge
In typical Scheel fashion, we decided to go overkill on the challenge: what is the minimum number of points achievable in a particular hand, given a configuration that describes what kinds of matches are possible?

Alex wanted to target not only Three thirteen but all other games of this family, so the configuration included a bunch of options so it can be flexible. The configuration assigns point values to cards and designates some as wildcards. We consider matches consisting of mostly normal (i.e. non-wild) cards as always valid, but it is configurable whether mostly wild groupings and/or wholly wild groupings are allowed. Furthermore, if mostly wild groupings are not allowed, you might want to consider non-joker wildcards as their normal rank (more on this below). And finally we have a few options for runs: aces being low/high/both, or runs just generally wrapping around (e.g. King Ace 2 3). And of course whether runs have to be of the same suit or not!

Okay, so we know that, for small hands with less than six cards, all of the cards would have to belong to a single group to achieve a score of 0, which wouldn’t be so hard to verify. But already due to the multiple rounds in Three thirteen, we had to consider hands with _any_ number of cards. So one part of the challenge is to determine different ways of grouping the hands, and find the optimal combination of those.

However, the bigger challenge that I haven’t mentioned yet is the presence of wildcards. Wildcards can stand for any particular card in order to complete a match. But what cards do you choose to pair a wildcard with? How do you minimize remaining points if there are competing ways to use it and no perfect solution for the hand? There’s a tension here between completing larger groups (e.g. a run 12_45) versus using up larger cards first (e.g. two 7s, which are actually worth more points). What’s best in a situation is influenced by what else is in the hand: maybe not matching the two sevens would free one up to be used for a run. It’s very subtle!

The game Three thirteen poses _additional_ challenges for this algorithm. For each round, not only is the joker a wildcard, but one additional wildcard is given for each round: starting with the 3 for the first round with 3 cards, and increasing with the number of cards up through the 10, Jack, Queen, and finally the King (which is the 13th rank, for the last round of course). _Furthermore_, in order to avoid a match that consists of more wildcards than normal cards, the special wildcard for the round _may_ be considered as a normal card, for the purpose of making a match. This means that 5_7_9 is a valid match with two jokers, even if the 7 is considered wild, but it would not be valid if the 7 was another joker (since 5___9 has more wildcards than normal cards, so it is not valid in the standard rules of Three thirteen).

Great. So not only do we have to find groups in the hand which satisfy certain constraints, while simultaneously assigning wildcards – we have to decide whether those wildcards are actually wild.

These are choices that players have to keep in mind all the time when considering their hands. They develop intuition for what matches are the most beneficial – but that intuition leads to the chance that they could get it wrong, which would be unacceptable for an algorithm.

Therefore, I focused on making sure the algorithm covered all possible cases, without refining the logic too much.

-----

## The Solution
The algorithm generally works by searching through the correct combinations of cards that make matches, and returns the minimum score of the “deadwood” resulting from each grouping (that is, the score of the leftover cards).

For efficiency, we also fix a max score to prune the search. This means that if we just want to ask whether the hand has 0 points, we don’t need to consider any groupings where there are unused cards. Not sure if it actually makes it faster, but it makes me feel better at least.

### Part 1: Choose and anonymize wildcards
My favorite insight is that it doesn’t matter what wildcards we assign where. Alex was trying to assign particular wildcards to particular spots, using up the highest-valued wildcards first, but that resulted in much more complicated code that duplicated similar logic in weird ways.

Unfortunately, there was going to be a problem with my anonymous approach: how do we know when to consider a wildcard as its rank? Obviously there are situations where it is beneficial, so we don’t want to accidentally assign it elsewhere first.

The short answer is we don’t even try. Instead, we just loop at the top level over trying each wildcard as itself (if it is not a joker, of course). In a worst-case scenario, this would be really inefficient – but since there are only a couple wildcards in each hand, it’s certainly worth the simplifications that happen elsewhere.

So, once and for all, we try all possible assignments of wildcards as their ranks, and from now on we can assume that wildcards are actually wildcards – and they all get to be anonymous, equally valid. Great!

### Part 2: Divide and conquer
This part isn’t essential to the success of the algorithm (and I don’t know whether it actually speeds it up – other than reducing one source of exponential complexity), but I think it is nevertheless a nice observation. In particular, it’s one that many players pick up on intuitively and it certainly speeds up their analyses!

Alex noticed that if you sort the cards in a hand, you can divide the hand at any gap of more than a card. I pointed out that it actually needed to be a gap of size greater than the number of wildcards available. But in the simple case of no wildcards, because the only matches are multiple of a kind and runs, this works: 7s and 9s will never interact if there are no 8s, so their solution spaces will be independent and we can minimize them separately.

So this is the second step in the algorithm: sort and divide the hand according to gaps larger than the number of wildcards available.

### Part 3: How to verify a match
This is the core part of the algorithm, particular since it’s where the configuration comes into play. We’ll be looking at all possible matches, so we need to make sure we know what matches look like and can verify they are indeed matches.

However, since I want to consider wildcards anonymously, I don’t actually return a boolean, like one would expect. Instead, I return a representation of an interval of the number of wildcards that would be compatible with the match, with a special value meaning that no match is possible no matter how many wildcards. (If matches can consist of mostly wildcards, the interval has no upper bound – otherwise, we need to limit how many could be used.)

For a whole grouping of a hand, we just use interval arithmetic: add the lower bounds and the number of additional wildcards that could be accepted.

Checking if all cards have the same value is pretty simple, then we just need to ensure we add wildcards so we have at least 3 cards in the group.

Checking for a run is a little more complicated, especially since runs can wrap. We want to measure the span of a run (from the lowest to the highest card), since that will indicate how many wildcards we need to fill the gaps (that is the span of the run minus the number of non-wild cards). So if runs can wrap around, we search for the largest gap, and say the run starts above that and ends below it. (And if aces are both high and low we only check for a gap at the start, if aces are only high we force the run to start at 2 or more.)

### Part 4: Look at all the matches
Yes, **all** the matches.

You could do some elegant algorithm to walk the lattice structure that arises from the combination of card suit and rank. Basically you search around for the closest cards (in rank or suit), and try each of them to make a match, or try to use a wildcard to bridge the gap to a further card.

I implemented that logic. It was fun to work on, but it was noticeably slower than the naïve algorithm of just trying every match! So that’s just what I do: look at every combination of cards, and ask how many wildcards are needed to make it a valid match, and then record it if it makes sense.

Next, now that we have a listing of the individual matches that can be tried, we want to find the combinations of disjoint matches that minimize the deadwood. We actually only need to consider maximal matches (matches which have no obvious extension to make it better), but again I ended up just coding it so it checks all combinations of matches that don’t overlap.

### Part 5: Putting it together
We have all the parts we need to find and check solutions, now to fit it all together.

As noted in part 1, this whole process takes place in a loop that tries all assignments of wildcards to be wild or normal, so none of the other logic has to care about this part of it.

Once we do that, we know the number of wildcards we have on hand, which we use for pruning the search along with the maximum score information.

So as the second step, we divide the hand as in part 2 (finding gaps larger than the number of wildcards), so we can focus on smaller parts of the problem independently.

For each division, we now get a list of all possible matches à la part 4, and then we look at all possible non-overlapping groupings from those matchings.

Note that each grouping (like an individual match) is associated with an interval of wildcards that it works for. We thus build up a map from number of wildcards to the best possible score we can get for it, for each division.

Finally, we do two final loops to get the actual minimum score: we choose how many wildcards to use up (preferably all of them!), and then we partition them into the different divisions (so if we have 3 wildcards across 2 divisions, we can assign 0 and 3, 1 and 2, 2 and 1, or 3 and 0). From the calculations we’ve done above, we can now lookup what the best score for the specified number of wildcards in each division is, and thus find the best score overall.

-----

## Takeaways
One of my main takeaways from writing this algorithm is that it just needs to be good enough: it just needs to make sure we explore all the possibilities, given that we have a way of recognizing valid results and scoring them to find the minimum. In particular, the algorithm technically has exponential complexity in parts (e.g. `O(2^n)` for enumerating all subsets, which is used in a few places), but because `n` here is either the total number of matches, cards, or wildcards, it remains quite small and it will run quickly enough for any given hand, since the hands are small, wildcards scarce, and matches not too common. In fact, as I mentioned in Part 4, a “smarter” algorithm (which was polynomial time) actually took more time to run! (Those ruinous constant factors …)

The main challenge is the non-locality of solutions: since the matches cannot overlap, choosing one means throwing out others, so a greedy algorithm would not suffice. But instead of backtracking, we just plan on enumerating all possibilities from the start, as I said before.

The two main insights were that we can keep wildcards anonymous and that when there is a gap that cannot be filled with the available wildcards, the lower and upper sides of the gap can be solved independently. These are both are useful intuitive strategies to help players solve cards in their head. Of course, human players have a better intuitive grasp of which numbers fit better with runs versus triplets, but computers are great at just churning through all the combinations.

Finally, the practical benefit of implementing these algorithms is that it helps the most complicated part of the game go more smoothly: the computer will guide users to the right answers of the essential questions “Can I go out now?” and “Am I getting my best possible score?” – in particular, avoiding mistakes of clicking the wrong buttons or not understanding how the grouping mechanism works.

### Future work
It would be nice to extend the algorithm so it returns the actual best grouping it found, along with explanations to walk the user through the reasoning or something like that. One main challenge would be finding where wildcards actually fit in, since we made them anonymous (it is implicitly calculated while verifying runs, but that data is never returned). And currently the error messages just tell the user _that_ a group of cards was not valid, with no explanation as to _why_ – so some feedback like “Runs need to be of the same suit!” or “Runs do not wrap around from King to Ace to Two!” or “Too many wildcards!” or “What the heck were you thinking?” would be great.

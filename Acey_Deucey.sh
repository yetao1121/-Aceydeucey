#!/bin/bash
#Aceydeucey -- 发牌方翻开两张牌，你来猜下一张牌的点数是否存在
# 这两张牌之间。 例如，两张牌是6和8，那么7在此之间，9则不在

function initializeDeck {
	# 生成一副牌
	# deck[]保存一副整齐的牌
	card=1
	while [ $card != 53 ] # 一副牌52张
	do
		deck[$card]=$card
		card=$(( $card + 1 ))
	done
}

function shuffleDeck {
	# 这并非真正的洗牌，只是从数组deck中随即抽取数值
	# 然后创建数组newdeck[], 作为“洗好的”牌
	# 在deck[]中抽取某张牌，被选中的牌会被0替换对应的元素值，然后将其
	# 放入newdeck[]中的随机位置，这样newdeck[]将是“洗好的”牌
	count=1

	while [ $count != 53 ]
	do
		pickCard
		newdeck[$count]=$picked
		count=$(( $count + 1 ))
	done
}

function pickCard {
	# 使用数组deck[]来查找哪张牌能用

	local errcount randomcard

	threshold=10  # 在遍历前，一张牌最多可以挑选多少次
	errcount=0

	# 随机挑一张还没有被选中过的牌，最多能挑$threshold次
	# 如果不行就遍历（为了避免总是挑到同一张已经发出的牌，陷入死循环）

	while [ $errcount -lt $threshold ]
	do
		randomcard=$(( ( $RANDOM % 52 ) + 1 ))
		errconut=$(( $errcount + 1 ))

		if [ ${deck[$randomcard]} -ne 0 ]
		then
			picked=${deck[$randomcard]}
			deck[$picked]=0 # 已选中，将其删除
			return $picked
		fi
	done

	# 如果运行到了这里，则说明没法随机挑出一张牌
	# 所以只能遍历数组，直到找到能用的牌

	randomcard=1

	while [ ${deck[$randomcard]} -eq 0 ]
	do
		randomcard=$(( $randomcard + 1 ))
	done

	picked=$randomcard
	deck[$picked]=0   #已选中，将其删除
		
	return $picked
}

function showCard {
	# 这里使用除法和求余运算获得牌的花色和点数，尽管在这个游戏中
	# 只有点数起作用。不过，表现形式很重要，这可以提高美观性

	card=$1

	if [ $card -lt 1 -o $card -gt 52 ]
	then
		echo "Bad card value: $card"
		exit 1
	fi

	# 除法和求余

	suit="$(( ( ( $card - 1) / 13 ) + 1))"
	rank="$(( $card % 13))"

	case $suit in
		1 ) suit="Hearts"   ;; # 红桃
		2 ) suit="Clubs"    ;; # 梅花
		3 ) suit="Spades"   ;; # 黑桃
		4 ) suit="Diamonds" ;; # 方块
		* ) echo "Bad suit value: $suit"
			exit 1
	esac

	case $rank in
		0 ) rank="King"     ;; # 老K
		1 ) rank="Ace"      ;; # 老A
		11) rank="Jack"     ;; # 老J
		12) rank="Queen"    ;; # 老Q
	esac

	cardname="$rank of $suit"
}

function dealCards {
	#Acey Deucey 要翻开两张牌
		
	card1=${newdeck[1]}  # 已经洗过牌了，我们这里取出最上面的
	card2=${newdeck[2]}  # 两张牌，然后悄悄地挑出第三张牌
	card3=${newdeck[3]}

	rank1=$(( ${newdeck[1]} % 13 )) # 获得牌的点数，简化后续计算
	rank2=$(( ${newdeck[2]} % 13 ))
	rank3=$(( ${newdeck[3]} % 13 ))

	# 将老K的点数修改成13，默认是0
	if [ $rank1 -eq 0 ] ; then
		rank1=13;
	fi
	if [ $rank2 -eq 0 ] ; then
		rank2=13;
	fi
	if [ $rank3 -eq 0 ] ; then
		rank3=13;
	fi

	# 现在来整理一下发出的牌，让第一张牌的点数总是小于第二张牌
		
	if [ $rank1 -gt $rank2 ]
	then
		temp=$card1; card1=$card2; card2=$temp
		temp=$rank1; rank1=$rank2; rank2=$temp
	fi

	showCard $card1 ; cardname1=$cardname
	showCard $card2 ; cardname2=$cardname

	showCard $card3 ; cardname3=$cardname # 这张牌还不能说

	echo "I've dealt:" ; echo " $cardname1" ; echo " $cardname2"
}

function introblurb {
	echo "welcome to Acey Deucey." 
	echo "The goal of this game is for you to correctly guess whether the third card is goning to be between the two cards"
	echo "I'll pull from the deck. For example, if I flip up a 5 of hearts and a jack of diamonds, you'd bet on whether the"
	echo "next card will have a higher rank than a 5 AND a lower rank than a jack(e.g., a 6, 7, 8, 9, or 10 of any suit)."
	echo "Ready? Let's go!"
}

#######################################
#############主代码部分################
#######################################

games=0
won=0

#运行程序先显示游戏规则
introblurb

while [ /bin/true ]
do

	initializeDeck
	shuffleDeck
	dealCards

	splitValue=$(( $rank2 - $rank1 ))

	if [ $splitValue -eq 0 ] ; then
		echo "No point in betting when they're the same rank!"
		continue
	fi

	/bin/echo -n "The spread is $splitValue. Do you think the next card will "
	/bin/echo -n "be between them ? (y/n/q)"
	read answer

	if [ "$answer" = "q" ] ; then
		echo ""
		echo "You played $games games and won $won times."
		exit 0
	fi

	echo "I picked: $cardname3"

	# 点数是否在前两张牌之间？ 让我们检查一下。记住，点数相等也是输

	if [ $rank3 -gt $rank1 -a $rank3 -lt $rank2 ] ; then # 赢了！
		winner=1
	else
		winner=0
	fi

	if [ $winner -eq 1 -a "$answer" = "y" ] ; then
		echo "You bet that it would be between the two, and it is. WIN!"
		won=$(( $won+1 ))
	elif [ $winner -eq 0 -a "$answer" = "n" ] ; then
		echo "You bet that it would not be between the two, and it is not. WIN!"
		won=$(( $won+1 ))
	else
		echo "Bad betting strategy. You lose."
	fi

	games=$(( $games + 1 )) # 玩了几局?

done
exit 0

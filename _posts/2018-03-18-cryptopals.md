---
layout: post
title: Cryptopals Crypto Challenge
date: 2018-03-18 15:27:31
permalink: cryptopals
---

> I recently discovered the [cryptopals](http://cryptopals.com) crypto challenges by nccgroup. I'll be recording my solutions here.

<h3>set1</h3>
```
import sys
from Crypto.Cipher import AES

def tobits(s):
    result = []
    for c in s:
        bits = bin(ord(c))[2:]
        bits = '00000000'[len(bits):] + bits
        result.extend([int(b) for b in bits])
    return result
# ----------------------------------

def hexTo64(hex):
	return HEX.decode('hex').encode('base64')

def fixedXOR(buf1, buf2):
	x = buf1.decode('hex')
	y = buf2.decode('hex')
	return "".join(chr(ord(a) ^ ord(b)) for a, b in zip(x, y))

#challenge2string1 = '1c0111001f010100061a024b53535009181c'
#challenge2string2 = '686974207468652062756c6c277320657965'
#print fixedXOR(hex1, hex2).encode('hex')

def singleByteXOR(input, key):
	output = ""
	for i in input:
		output += chr(ord(i) ^ ord(key))
	return output

# challenge2 end #

frequency = {
' ': 20,
'e': 12.02,
't': 9.10,
'a': 8.12,
'o': 7.68,
'i': 7.31,
'n': 6.95,
's': 6.28,
'r': 6.02,
'h': 5.92,
'd': 4.32,
'l': 3.98,
'u': 2.88,
'c': 2.71,
'm': 2.61,
'f': 2.30,
'y': 2.11,
'w': 2.09,
'g': 2.03,
'p': 1.82,
'b': 1.49,
'v': 1.11,
'k': 0.69,
'x': 0.17,
'q': 0.11,
'j': 0.10,
'z': 0.07
}


class Result:
	def __init__(self, score, key, result):
		self.score = score
		self.key = key
		self.result = result

	def __eq__(self, other):
		return self.result == other.result

	def __lt__(self, other):
		return self.score < other.score

	def printObject(self):
		print('Key: ' + self.key + " Score: " + str(self.score) + " Phrase: " + str(self.result) + "\n")

	def __iter__(self):
		return self

def frequencyInEnglish(char):
	return frequency.get(char.lower(), 0)

def smartSingleByteXOR(input):
	arr = []
	options='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 +-:;'
	for key in options:
		score = 0
		result = singleByteXOR(input, key)
		for char in result:
			if True: # ((ord(char) in range(97,122)) or (ord(char) in range(64i,90) or (ord(char) == 32))):
				score += frequencyInEnglish(char)
		arr.append(Result(int(100*(float(score)/float(len(result)))), key, result))
	# Return sorted list
	arr.sort()
	return arr


challengeThreeString='1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736'.decode('hex')
#for ans in smartSingleByteXOR(challengeThreeString):
#	ans.printObject()
#print smartSingleByteXOR(challengeThreeString)[-1].printObject()

# challenge 3 end #

def detectSingleCharacterXOR(largeFile):
	bestCandidates = []
	lines = []
	with open(largeFile) as f:
		lines = f.readlines()
	lines = map(lambda x: x.decode('hex'), map(lambda x: x.split('\n')[0], lines))
#	print lines

	for l in lines:
		bestCandidates.append(smartSingleByteXOR(l)[-1])

	bestCandidates.sort()
	return bestCandidates


# for ans in detectSingleCharacterXOR('4.txt'):
#	ans.printObject()


# challenge 4 end #

# challenge 5 start #

c5input = '''Burning 'em, if you ain't quick and nimble
I go crazy when I hear a cymbal'''

c5output = '0b3637272a2b2e63622c2e69692a23693a2a3c6324202d623d63343c2a26226324272765272a282b2f20430a652e2c652a3124333a653e2b2027630c692b20283165286326302e27282f'

def repeatedXOR(inputText, key):
	output = ""
	modValue = len(key)
	for i in range(0,len(inputText)):
		output += chr(ord(inputText[i]) ^ ord(key[i % modValue]))

	return output


#print repeatedXOR(c5input, 'ICE').encode('hex')
#print repeatedXOR(c5output.decode('hex'), 'ICE')


# challenge 5 done #

# challenge 6 start #

c6example1 = 'this is a test'
c6example2 = 'wokka wokka!!!'

def editDistance(str1, str2):
	total = 0
	b1 = tobits(str1)
	b2 = tobits(str2)
	for a,b in zip(b1, b2):
		if a != b:
			total += 1
	return total

# print editDistance(c6example1, c6example2)


def theThreeMostLikelyKeySizes(input):
	distances = []
	for KEYSIZE in range(2,40):
		first =  input[ : KEYSIZE]
		second = input[KEYSIZE : KEYSIZE * 2]
		third =  input[KEYSIZE * 2 : KEYSIZE * 3]
		fourth = input[KEYSIZE * 3 : KEYSIZE * 4]
		normalized = float(editDistance(first, second) + editDistance(second, third) + editDistance(third,fourth)) / (KEYSIZE * 3)
		distances.append((KEYSIZE, normalized))
	return map(lambda x: x[0], sorted(distances, key=lambda tup:tup[1])[:3])


fileSix = ''
with open('6.txt', 'r') as myfile:
    fileSix=myfile.read().replace('\n', '').decode('base64')

#print theThreeMostLikelyKeySizes(fileSix)

alphabetTestInput = 'abcdefghijklmnopqrstuvwxyz'

def breakIntoBlocksOfSizeN(theFile, n):
	output = []
	for i in range(0, len(theFile)+1, n):
		#print "from: " + str(i) + " to: " + str(i+n-1) + "\n"
		output.append(theFile[i:i+n])
	return output


#testBrokenBlocks = breakIntoBlocksOfSizeN(fileSix, 29)
#print testBrokenBlocks

def transposeBlocks(blocks, n):
	# Create array of empty strings, one for each tranposed string
	output = [''] * n
	# Start sifting bits from each block into correct string
	for b in blocks:
		for whichBucket in range(0,len(b)):
			#print "len is: " + str(len(b))
			output[whichBucket] += b[whichBucket]
	return output

#print transposeBlocks(testBrokenBlocks, 29)


def breakRepeatKeyXOR(input, keySizes):
	finalArr=[]
	for KEYSIZE in keySizes:
		finalString = ""
		transposed = transposeBlocks(breakIntoBlocksOfSizeN(input, KEYSIZE), KEYSIZE)
		for t in transposed:
			finalString += smartSingleByteXOR(t)[-1].key
		finalArr.append(finalString)

	return finalArr


#keys =  breakRepeatKeyXOR(fileSix,theThreeMostLikelyKeySizes(fileSix))
#print keys
#print repeatedXOR(fileSix, keys[2])


# END 6

# START 7

with open('7.txt', 'r') as myfile:
    fileSeven=myfile.read().replace('\n', '').decode('base64')


sevenKey = b'YELLOW SUBMARINE'
aesKey = AES.new(sevenKey, AES.MODE_ECB)
#print aesKey.decrypt(fileSeven)

# END 7

# START 8

fileEightArray = []
with open('8.txt', 'r') as myfile:
    fileEight=myfile.read()
fileEight = fileEight.split('\n')
fileEightArray =  map(lambda x: x.decode('hex'), fileEight)

#print fileEightArray


## Detect whether ANY blocks of 16 bytes

def howManyUniqueBlocks(arr):
    frequencies = []
    for item in arr:
        frequency = {}
        splitByBytes = [item[i:i+16] for i in range(0, len(item), 16)]
        for bytes in splitByBytes:
            if bytes in frequency:
                frequency[bytes] += 1
                print item.encode('hex') # FOR THIS CHALLENGE, the only
                                         # sequence of bytes > 1 is the answer!!
            else:
                frequency[bytes] = 1
        # Could do further analysis here, but we print the answer above.


#data = ['\x00\x00\x00\x00\x00\x00', '\x00\x00\x00\x00\x00\x00']
howManyUniqueBlocks(fileEightArray)
# d880619740a8a19b7840a8a31c810a3d08649af70dc06f4fd5d2d69c744cd283e2dd0
# 52f6b641dbf9d11b0348542bb5708649af70dc06f4fd5d2d69c744cd2839475c9dfdbc1d46
# 597949d9c7e82bf5a08649af70dc06f4fd5d2d69c744cd28397a93eab8d6aecd56648915478
# 9a6b0308649af70dc06f4fd5d2d69c744cd283d403180c98c8f6db1f2a3f9c4040deb0ab51b29
# 933f2c123c58386b06fba186a



## set 1 end

```

<h3>to be continued....</h3>

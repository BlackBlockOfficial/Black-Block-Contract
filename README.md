# ![image](https://github.com/BlackBlockOfficial/BlackBlockContract/assets/136055194/8b0c8ba7-77df-4e62-94b9-0eda252da786) BlackBlockContracts
<h3>Black Block, is a cryptocurrency developed to protect small investors from violent market swings.</h3>

<h2>Official link:</h2>

Website: <a href="https://blackblock.community" target="_blank">blackblock.community</a>
<br>
Twitter: <a href="https://twitter.com/i_m_black_block" target="_blank">@i_m_black_block</a>
<br>
Telegram: <a href="https://t.me/blackblockofficial" target="_blank">blackblockofficial</a>
<br>
Discord: <a href="https://discord.gg/mMg45xzDG5" target="_blank">BlackBlock</a>
<br>

<h2>SUMMARY DESCRIPTION</h2>

<strong>BlackBlock Contract Composition</strong><br>
The token was created following openzeppelin standards, so it is an ERC20 with features such as snapshot, burning, and permit, which are common to many other tokens.

<strong>BlockLiquidity Contract Composition</strong><br>
The BlockLiquidity Contract was created using the Uniswap v3 interface and libraries, along with some openzeppelin contracts like SafeMath. BlockLiquidity is based on two main elements: 2B Token (BlackBlock) and liquidity (tokenID) created on Uniswap V3. The liquidity contract has three main functions: Monitoring, Swap, and Collect.

<h2>MONITORING FUNCTION</h2>

<strong>Introduction</strong><br>
The Monitoring function is crucial for the liquidity of BlackBlock as it assesses the behavior of the 2B tokens within the pool. If the amount of 2B tokens decreases in the pool, it indicates that the token has been bought. Conversely, if the amount increases, it signifies that the token has been sold. For instance, if the liquidity pool comprises WMATIC+2B and the 2B token is purchased on Uniswap, the Monitoring function will provide the amount, tokenId, and the address of 2B. This will trigger the sale of 2B via the internal Swap function and result in obtaining WMATIC, causing a decrease in the price of 2B. Similarly, if the 2B token is sold on Uniswap, the Monitoring function will provide the amount, tokenId, and the address of WMATIC. This will initiate the sale of WMATIC through the internal Swap function and lead to the acquisition of 2B, causing an increase in the price of 2B. The parameters returned by Monitoring, such as amount, tokenId, and tokenIn, are determined automatically and cannot be influenced in any way.

<strong>Questions</strong><br>
How does Monitoring decide how many tokens to sell?
And how does BlockLiquidity limit boots and large wallets?

<strong>Answers</strong><br>
Monitoring determines the number of tokens to sell through an internal function called Percentage, which calculates the percentage of token sales based on a specified range.

<strong>The ranges are as follows:</strong>
<pre>
    /********************************Percentage*********************************/

    Range: amount  100,000,000
    Percentage: 1%
    Range: amount  100,000,000 && amount  500,000,000
    Percentage: 5%
    Range: amount  500,000,000 && amount  1,000,000,000
    Percentage: 10%
    Range: amount  1,000,000,000 && amount  5,000,000,000
    Percentage: 15%
    Range: amount  5,000,000,000 && amount  10,000,000,000
    Percentage: 20%
    Range: amount  10,000,000,000 && amount  50,000,000,000
    Percentage: 25%
    Range: amount  50,000,000,000 && amount  100,000,000,000
    Percentage: 30%
    Range: amount  100,000,000,000 && amount  500,000,000,000
    Percentage: 35%
    Range: amount  500,000,000,000 && amount  1,000,000,000,000
    Percentage: 40%
    Range: amount  1,000,000,000,000
    Percentage: 45%
    
</pre>

<strong>How range is used?</strong><br>
Let's give an example: if the difference between the previous amount and the current one has a value of 500,000,000 tokens, it will fall within range N°3, and the returned percentage will be 15%

<strong>How the liquidity difference is calculated?</strong><br>
As mentioned earlier, BlockLiquidity monitors the liquidity within the pool, enabling it to determine if the amount of 2B has increased or decreased.
The liquidity difference is calculated by subtracting the previous 2B amount from the current 2B amount
If the 2B amount has decreased within the pool, the calculation is as follows: previous 2B - current 2B = amount (BlockLiquidity will sell 2B).
If the 2B amount has increased within the pool, the calculation is as follows: current 2B - previous 2B = amount (BlockLiquidity will sell WMATIC).
The obtained amount is then passed to the aforementioned function, which returns the corresponding percentage..
Therefore, the larger the difference between the previous and current 2B amounts, the higher the percentage returned, or vice versa.

<strong>Now let's do a more complete example:</strong><br>
Suppose we have an internal reserve in BlockLiquidity of 500,000,000,000 2B tokens and 100,000 WMATIC tokens.
We have liquidity in the pool of 1,000,000,000,000 2B tokens, and a user buys 100,000,000,000 2B tokens on Uniswap.
BlockLiquidity will compare the previous amount in the pool (1,000,000,000,000 2B tokens) with the new amount (900,000,000,000 2B tokens), resulting in a difference of 100,000,000,000 2B tokens.
This difference is then passed to the percentage function, which in this case returns the percentage within range N°8, which is equal to 35%.
BlockLiquidity employs different calculation methods for selling based on the specific situation.

<strong>Example in case of selling 2B tokens:</strong><br>
For the sale of 2Bs, the calculation is performed either on the reserve of 500,000,000,000 2Bs present in BlockLiquidity or on the amount obtained from the previous calculation (100,000,000,000 2Bs). The function compares the two values and returns the lower value. In this example, the lower value is 100,000,000,000 2Bs

<code>The sales amount will be = (100,000,000,000 2B tokens * 35 / 100) = 35,000,000,000 2B tokens.</code>

<strong>Example in case of selling MATIC tokens:</strong><br>
For the sale of WMATIC, the calculation is performed based on the WMATIC reserve present within BlockLiquidity.

<code>The sales amount will be = (100,000 WMATIC tokens * 35 / 100) = 35,000 WMATIC tokens.</code>

<strong>Conclusion</strong><br>
The resulting tokens will be sold via the internal swap mechanism automated by Gelato
Technically, what happens is that the system limits excessive price changes, whether upwards or downwards.
In conclusion, with each purchase of 2Bs on Uniswap, the price tends to rise, immediately after, BlockLiquidity aims to reduce the price slightly. With each sale of 2Bs on Uniswap, the price tends to fall, and BlockLiquidity aims to increase it using the explained mechanism

<h2>SWAP FUNCTION</h2>

<strong>What is the swap function for?</strong><br>
The Swap function is used for token exchange and also triggers the Collect function internally.
It's important to note that when the Swap function exchanges tokens for 2B, the received 2B tokens are burned or destroyed, equivalent to the amount received.
This process reduces the circulating supply of 2Bs and tends to increase the price.
It's important to clarify that not only BlockLiquidity can burn the tokens.

<h2>COLLECT FUNCTION</h2>

<strong>What is the function of Collect?</strong><br>
The Collect function gathers the profits obtained from the trade on the liquidity transferred to BlockLiquidity and allocates them as a reserve within the BlockLiquidity contract.
This reserve is intended to sustain the trading cycle.

<h2>BlackBlock was created with:</h2>

OpenZeppelin Contracts (last updated v4.8.0).
<br>
Uniswap v3-core.
<br>
Uniswap v3-periphery.
<br>
Gelato network


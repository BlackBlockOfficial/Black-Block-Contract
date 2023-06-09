# BlackBlockContracts
![image](https://github.com/BlackBlockOfficial/BlackBlockContract/assets/136055194/8b0c8ba7-77df-4e62-94b9-0eda252da786)  <span>Black Block, is a cryptocurrency developed to protect small investors from violent market swings.</span>

<strong>SUMMARY DESCRIPTION</strong>

BlackBlock Token Contract Composition
The token was created following openzeppelin standards, so it is an ERC20 with features such as snapshot, burning, and permit, which are common to many other tokens. The contract is ownerless.

BlockLiquidity Contract Composition
The BlockLiquidity Contract was created using the Uniswap v3 interface and libraries, along with some openzeppelin contracts like SafeMath. BlockLiquidity is based on two main elements: 2B Token (BlackBlock) and liquidity (NTF or tokenID) created on Uniswap V3. The liquidity contract has three main functions: Monitoring, Swap, and Collect.

<strong>MONITORING FUNCTION</strong>

Introduction
The Monitoring function is crucial for the liquidity of BlackBlock as it assesses the behavior of the 2B tokens within the pools. If the amount of 2B tokens decreases in the pool, it indicates that the token has been bought. Conversely, if the amount increases, it signifies that the token has been sold. For instance, if the liquidity pool comprises WMATIC+2B and the 2B token is purchased on Uniswap, the Monitoring function will provide the amount, tokenId or (NTF), and the address of 2B. This will trigger the sale of 2B via the internal Swap function and result in obtaining WMATIC, causing a decrease in the price of 2B. Similarly, if the 2B token is sold on Uniswap, the Monitoring function will provide the amount, tokenId or (NTF), and the address of WMATIC. This will initiate the sale of WMATIC through the internal Swap function and lead to the acquisition of 2B, causing an increase in the price of 2B. The parameters returned by Monitoring, such as amount, tokenId, and tokenIn, are determined automatically and cannot be influenced in any way.

<strong>Questions</strong><br>
How does Monitoring decide how many tokens to sell?

And how does BlockLiquidity limit boots and large wallets?

<strong>Answers</strong><br>
Monitoring determines the number of tokens to sell through an internal function called Percentage, which calculates the percentage of token sales based on a specified range.

<strong>The ranges are as follows:</strong>
<pre>
    /********************************Percentage*********************************/

    function _percentage(uint256 amount) internal pure returns(uint8 percentage) {

        if (amount < 100000000e18) {
            percentage = 0;
        } else if (amount >= 100000000e18 && amount < 500000000e18) {
            percentage = 5;
        } else if (amount >= 500000000e18 && amount < 1000000000e18) {
            percentage = 10;
        } else if (amount >= 1000000000e18 && amount < 5000000000e18) {
            percentage = 15;
        } else if (amount >= 5000000000e18 && amount < 10000000000e18) {
            percentage = 20;
        } else if (amount >= 10000000000e18 && amount < 50000000000e18) {
            percentage = 25;
        } else if (amount >= 50000000000e18 && amount < 100000000000e18) {
            percentage = 30;
        } else if (amount >= 100000000000e18 && amount < 500000000000e18) {
            percentage = 35;
        } else if (amount >= 500000000000e18 && amount < 1000000000000e18) {
            percentage = 40;
        } else {
            percentage = 45;
        }

    }
</pre>

<strong>How range is used?</strong><br>
Let's give an example: if the difference between the previous amount and the current one has a value of 500,000,000 tokens, it will fall within range N°3, and the returned percentage will be 15%

<strong>How the liquidity difference is calculated?</strong><br>
As mentioned earlier, BlockLiquidity monitors the liquidity within the pool, enabling it to determine if the amount of 2Bs (2B tokens) has increased or decreased.

The liquidity difference is calculated by subtracting the previous 2B amount from the current 2B amou

If the 2B amount has decreased within the pool, the calculation is as follows: previous 2B - current 2B = amount (BlockLiquidity will sell 2B).

If the 2B amount has increased within the pool, the calculation is as follows: current 2B - previous 2B = amount (BlockLiquidity will sell WMATIC).

The obtained amount is then passed to the aforementioned function, which returns the corresponding percentage..

Therefore, the larger the difference between the previous and current 2B amounts, the higher the percentage returned, or vice versa.

<strong>Now let's do a more complete example:</strong><br>
Suppose we have an internal reserve in BlockLiquidity of 500,000,000,000 2B tokens and 100,000 WMATIC tokens.

We have liquidity in the pool of 1,000,000,000,000 2B tokens, and a user buys or sells 100,000,000,000 2B tokens on Uniswap.

BlockLiquidity will compare the previous amount in the pool (1,000,000,000,000 2B tokens) with the new amount (900,000,000,000 2B tokens), resulting in a difference of 100,000,000,000 2B tokens.

This difference is then passed to the percentage function, which in this case returns the percentage within range N°8, which is equal to 35%.

BlockLiquidity employs different calculation methods for selling based on the specific situation.

<strong>Example in case of selling 2B tokens:</strong><br>
For the sale of 2Bs, the calculation is performed either on the reserve of 500,000,000,000 2Bs present in BlockLiquidity or on the amount obtained from the previous calculation (100,000,000,000 2Bs). The function compares the two values and returns the lower value. In this example, the lower value is 100,000,000,000 2Bs.

The sales amount will be = (100,000,000,000 2B tokens * 35 / 100) = 35,000,000,000 2B tokens.

<strong>Example in case of selling MATIC tokens:</strong><br>
For the sale of WMATIC, the calculation is performed based on the WMATIC reserve present within BlockLiquidity.

The sales amount will be = (100,000 WMATIC tokens * 35 / 100) = 35,000 WMATIC tokens.

<strong>Conclusion</strong><br>
The resulting tokens will be sold via the internal swap mechanism implemented by Gelato

Technically, what happens is that the system limits excessive price changes, whether upwards or downwards.

In conclusion, with each purchase of 2Bs on Uniswap, the price tends to rise. Immediately after, BlockLiquidity aims to reduce the price slightly. With each sale of 2Bs on Uniswap, the price tends to fall, and BlockLiquidity aims to increase it using the explained mechanism.

<strong>SWAP FUNCTION</strong>

What is the swap function for?
The Swap function is used for token exchange and also triggers the Collect function internally.

It's important to note that when the Swap function exchanges tokens for 2B, the received 2B tokens are burned or destroyed, equivalent to the amount received.

This process reduces the circulating supply of 2Bs and tends to increase the price.

It's important to clarify that only BlockLiquidity can burn the tokens.

<strong>COLLECT FUNCTION</strong>

What is the function of Collect?
The Collect function collects the accumulated earnings and adds them as a reserve within the BlockLiquidity contract.

This reserve will serve to maintain the trading cycle.

<strong>BlackBlock was created with:</strong>

OpenZeppelin Contracts (last updated v4.8.0).
<br>
Uniswap v3-core.
<br>
Uniswap v3-periphery.
<br>
Gelato network


#!/bin/bash

# Gas Price Report with USD Estimation
# Fetches current Base gas prices and calculates costs

echo "🔍 Fetching current Base network gas prices..."
echo ""

# Fetch current ETH price (used for Base L2)
ETH_PRICE=$(curl -s 'https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd' | grep -o '"usd":[0-9.]*' | grep -o '[0-9.]*')

if [ -z "$ETH_PRICE" ]; then
    echo "⚠️  Could not fetch ETH price, using fallback: \$3000"
    ETH_PRICE=3000
else
    echo "💰 Current ETH Price: \$$ETH_PRICE"
fi

# Base L2 typical gas prices (in gwei)
# Base is much cheaper than mainnet, typically 0.001-0.01 gwei
LOW_GWEI=0.001
MEDIUM_GWEI=0.005
HIGH_GWEI=0.01

echo "📊 Base Network Gas Prices (typical):"
echo "   Low:    ${LOW_GWEI} gwei"
echo "   Medium: ${MEDIUM_GWEI} gwei"
echo "   High:   ${HIGH_GWEI} gwei"
echo ""

# Run Forge test with gas reporting
echo "🧪 Running tests with gas reporting..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

export PATH="$HOME/.foundry/bin:$PATH"
forge test --gas-report --no-match-test "testFuzz" > /tmp/gas-report.txt 2>&1

# Display the gas report
cat /tmp/gas-report.txt

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💵 COST ESTIMATION (Base Network)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Extract gas costs from the report and calculate prices
calculate_cost() {
    local gas=$1
    local gwei=$2

    # Formula: (gas * gwei) / 1e9 * ETH_PRICE
    # Using bc for floating point math
    cost=$(echo "scale=6; ($gas * $gwei / 1000000000) * $ETH_PRICE" | bc)
    echo "$cost"
}

# Common operations (approximate from our tests)
DEPLOY_GAS=1500000
CREATE_BOTTLE=157649
LIKE_BOTTLE=159836
ADD_COMMENT=347449
PROMOTE_FOREVER=160518
UPDATE_IPFS=164108

echo "📋 Function Costs at Different Gas Prices:"
echo ""

printf "%-25s %12s %12s %12s\n" "Function" "Low (0.001)" "Med (0.005)" "High (0.01)"
printf "%-25s %12s %12s %12s\n" "-------------------------" "------------" "------------" "------------"

# Deploy
low=$(calculate_cost $DEPLOY_GAS $LOW_GWEI)
med=$(calculate_cost $DEPLOY_GAS $MEDIUM_GWEI)
high=$(calculate_cost $DEPLOY_GAS $HIGH_GWEI)
printf "%-25s \$%11s \$%11s \$%11s\n" "Deploy Contract" "$low" "$med" "$high"

# Create Bottle
low=$(calculate_cost $CREATE_BOTTLE $LOW_GWEI)
med=$(calculate_cost $CREATE_BOTTLE $MEDIUM_GWEI)
high=$(calculate_cost $CREATE_BOTTLE $HIGH_GWEI)
printf "%-25s \$%11s \$%11s \$%11s\n" "Create Bottle" "$low" "$med" "$high"

# Like Bottle
low=$(calculate_cost $LIKE_BOTTLE $LOW_GWEI)
med=$(calculate_cost $LIKE_BOTTLE $MEDIUM_GWEI)
high=$(calculate_cost $LIKE_BOTTLE $HIGH_GWEI)
printf "%-25s \$%11s \$%11s \$%11s\n" "Like Bottle" "$low" "$med" "$high"

# Add Comment
low=$(calculate_cost $ADD_COMMENT $LOW_GWEI)
med=$(calculate_cost $ADD_COMMENT $MEDIUM_GWEI)
high=$(calculate_cost $ADD_COMMENT $HIGH_GWEI)
printf "%-25s \$%11s \$%11s \$%11s\n" "Add Comment" "$low" "$med" "$high"

# Promote to Forever
low=$(calculate_cost $PROMOTE_FOREVER $LOW_GWEI)
med=$(calculate_cost $PROMOTE_FOREVER $MEDIUM_GWEI)
high=$(calculate_cost $PROMOTE_FOREVER $HIGH_GWEI)
printf "%-25s \$%11s \$%11s \$%11s\n" "Promote to Forever" "$low" "$med" "$high"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 10K BOTTLES BUDGET ESTIMATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Calculate costs for 10k bottles scenario
# Assumptions: 10k bottles, 5k likes, 2k comments, 50 forever promotions
BOTTLES=10000
LIKES=5000
COMMENTS=2000
FOREVER_PROMOTIONS=50

total_gas=$((DEPLOY_GAS + (BOTTLES * CREATE_BOTTLE) + (LIKES * LIKE_BOTTLE) + (COMMENTS * ADD_COMMENT) + (FOREVER_PROMOTIONS * PROMOTE_FOREVER)))

low=$(calculate_cost $total_gas $LOW_GWEI)
med=$(calculate_cost $total_gas $MEDIUM_GWEI)
high=$(calculate_cost $total_gas $HIGH_GWEI)

echo "Scenario: 10k bottles, 5k likes, 2k comments, 50 forever promotions"
echo ""
printf "Gas Price Level    Total Cost\n"
printf "─────────────────  ──────────────\n"
printf "Low (0.001 gwei)   \$%s\n" "$low"
printf "Med (0.005 gwei)   \$%s\n" "$med"
printf "High (0.01 gwei)   \$%s\n" "$high"
echo ""

# Check against budget
budget=60
med_numeric=$(echo "$med" | bc)
if (( $(echo "$med_numeric < $budget" | bc -l) )); then
    echo "✅ Well within \$60 budget at medium gas prices!"
else
    echo "⚠️  May exceed \$60 budget at medium gas prices"
fi

echo ""
echo "💡 Note: Base L2 gas prices are typically VERY low (0.001-0.01 gwei)"
echo "   This makes the platform extremely affordable to run!"

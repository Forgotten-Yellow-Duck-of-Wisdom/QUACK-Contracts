// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFV2PlusWrapperInterface {
    /**
     * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
     * be relied option within the same transaction that the request was made.
     */
    function lastRequestId() external view returns (uint256);

    /**
     * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
     * @notice block.
     *
     * @dev This function relies on the transaction gas price which is not automatically set during
     * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
     *
     * @param _callbackGasLimit is the gas limit used to estimate the price.
     */
    function calculateRequestPrice(uint32 _callbackGasLimit, uint32 _numWords) external view returns (uint256);

    /**
     * @notice Calculates the price of a VRF request in native with the given callbackGasLimit at the current
     * @notice block.
     *
     * @dev This function relies on the transaction gas price which is not automatically set during
     * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
     *
     * @param _callbackGasLimit is the gas limit used to estimate the price.
     */
    function calculateRequestPriceNative(uint32 _callbackGasLimit, uint32 _numWords) external view returns (uint256);

    /**
     * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
     *
     * @dev This is a convenience function that can be called in simulation to better understand
     * @dev pricing.
     *
     * @param _callbackGasLimit is the gas limit used to estimate the price.
     * @param _requestGasPriceWei is the gas price in wei used for the estimation.
     */
    function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei)
        external
        view
        returns (uint256);

    /**
     * @notice Estimates the price of a VRF request in native with a specific gas limit and gas price.
     *
     * @dev This is a convenience function that can be called in simulation to better understand
     * @dev pricing.
     *
     * @param _callbackGasLimit is the gas limit used to estimate the price.
     * @param _requestGasPriceWei is the gas price in wei used for the estimation.
     */
    function estimateRequestPriceNative(uint32 _callbackGasLimit, uint256 _requestGasPriceWei)
        external
        view
        returns (uint256);

    /**
     * @notice Requests randomness from the VRF V2 wrapper, paying in native token.
     *
     * @param _callbackGasLimit is the gas limit for the request.
     * @param _requestConfirmations number of request confirmations to wait before serving a request.
     * @param _numWords is the number of words to request.
     */
    function requestRandomWordsInNative(
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords,
        bytes calldata _extraArgs
    ) external payable returns (uint256 requestId);

    function getConfig()
        external
        view
        returns (
            int256 fallbackWeiPerUnitLink,
            uint32 stalenessSeconds,
            uint32 fulfillmentFlatFeeNativePPM,
            uint32 fulfillmentFlatFeeLinkDiscountPPM,
            uint32 wrapperGasOverhead,
            uint32 coordinatorGasOverheadNative,
            uint32 coordinatorGasOverheadLink,
            uint16 coordinatorGasOverheadPerWord,
            uint8 wrapperNativePremiumPercentage,
            uint8 wrapperLinkPremiumPercentage,
            bytes32 keyHash,
            uint8 maxNumWords
        );
}

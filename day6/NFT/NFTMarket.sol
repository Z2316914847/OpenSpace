// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "111/day6/ERC20.sol";
import "111/day6/ownerNFT.sol";

// 编写一个简单的 NFTMarket 合约，使用自己发行的ERC20 扩展 Token 来买卖 NFT， NFTMarket 的函数有：
//   list() : 实现上架功能，NFT 持有者可以设定一个价格（需要多少个 Token 购买该 NFT）并上架 NFT 到 NFTMarket，
//   上架之后，其他人才可以购买。 buyNFT() : 普通的购买 NFT 功能，用户转入所定价的 token 数量，获得对应的 NFT。
//   实现ERC20 扩展 Token 所要求的接收者方法 tokensReceived  ，在 tokensReceived 中实现NFT 
//   购买功能(注意扩展的转账需要添加一个额外数据参数)。

// token和tokenBank关系：货币资产(token)和银行(tokenBank)，在区块链上，token的发行量由token约定，转账只不过是钱从这个地址转到另一个地址
//   

/*
   遇到的问题
       1.上架NFT时market需不需要获得授权
            1.不获取授权（合约代码在最下面）：只需记录NFT的出售信息（如价格），NFT仍然在卖家钱包中。购买（buyNFT）​​：买家支付代币，
                然后市场合约通知卖家将NFT转移给买家。​如何确保卖家履约​：买家付款后，卖家必须发送NFT。
                这通常通过智能合约的原子交易来解决，但在非托管模式下，需要额外的机制（如信誉系统、仲裁）来保证。然而，在链上实现原子交易是更安全的方式。
            2.获取授权：在上架时，我们要求卖家已经授权市场合约可以操作其NFT（通过approve或setApprovalForAll）。
                这样在购买时，市场合约才能以卖家的身份转移NFT（因为市场合约被卖家授权了）。在购买时，我们首先转移代币，然后转移NFT。
                如果NFT转移失败（比如卖家已经撤回了授权或者卖掉了NFT），那么整个交易会回滚，代币转移也会撤销，从而保证原子性。
            3.结构体没有默认值：没有直接判断结构体是否为空的语法，需通过检查其关键成员的值来间接判断

*/

// 上架、买卖NFT、这个合约不放token(写一个函数，让他处理token存放问题)
contract NFTMarket{
    BaseERC20 public token;
    ERC721 public nft;

    constructor(string memory _name, string memory _symbol, string memory _baseURI){
        token = new BaseERC20();
        nft = new ERC721(_name, _symbol, _baseURI);
    }
    
    struct nftInfo{
        uint256 tokenId;
        uint256 price;  
        address sellAddress;  // 卖家地址
        address nftContract;  // NFT合约地址
        bool isActive;       // 是否处于活跃状态
    }

    mapping(uint256 => nftInfo) public nftListInfo;
    // mapping(address=>nftInfo) public  nftListInfo;  // 我自己写的，有机会写一下，看能不能实现

    // 实现上架功能，NFT 持有者可以设定一个价格（需要多少个 Token 购买该 NFT）并上架 NFT 到 NFTMarket，
    //   上架之后，其他人才可以购买
    function list(uint256 tokenId, uint256 price) public {
        // market需不需要获得授权、这里时获取授权，合约最下面由上架时Market不获取授权
        require(nft.ownerOf(tokenId) != address(0), "tokenId not exist" );
        require(nft.ownerOf(tokenId) == msg.sender, "You are not the owner of the NFT");
        require(price > 0, "NFTMarket: price must be greater than zero");

        // 将nft临时授权给market合约
        nft.approve(address(this), tokenId);
        nftListInfo[tokenId] = nftInfo(tokenId, price, msg.sender, address(nft), true);
        // nftListInfo[tokenId] = nftInfo({tokenId, price, msg.sender, address(nft), true});


        // 上架事件
    }

    // 普通的购买 NFT 功能，用户转入所定价的 token 数量，获得对应的 NFT。
    function buyNFT(address buyAddress, uint256 price, uint256 tokenId) public {
        // 接受地址部位空，价格是否合适
        require(nftListInfo[tokenId].sellAddress != address(0), "tokenId not exist" );
        require(nftListInfo[tokenId].price >= price, "The purchase price must be greater than the set price" );
        require(buyAddress!=address(0), "The purchase address cannot be empty");
        //买家在token合约的address减钱，卖家加钱
        token.transfer(nftListInfo[tokenId].sellAddress, price);
        // NFT同理
        nft.safeTransferFrom(nftListInfo[tokenId].sellAddress, buyAddress, tokenId);
        // 购买完成事件
    }

    // 欠实现bank获取token：实现tokensReceived接口，处理通过transferWithCallback接收到的代币
    function tokensReceived(address from, uint256 amount, bytes calldata data) public returns (bool) {
        // // 检查调用者是否为支付代币合约
        // require(msg.sender == address(paymentToken), "NFTMarket: caller is not the payment token contract");
        
        // // 解析附加数据，获取listingId
        // require(data.length == 32, "NFTMarket: invalid data length");
        // uint256 listingId = abi.decode(data, (uint256));
        
        // // 检查上架信息是否存在且处于活跃状态
        // Listing storage listing = listings[listingId];
        // require(listing.isActive, "NFTMarket: listing is not active");
        
        // // 检查转入的代币数量是否等于NFT价格
        // require(amount == listing.price, "NFTMarket: incorrect payment amount");
        
        // // 将上架信息标记为非活跃
        // listing.isActive = false;
        
        // // 将代币转给卖家
        // bool success = paymentToken.transfer(listing.seller, amount);
        // require(success, "NFTMarket: token transfer to seller failed");
        
        // // 处理NFT转移（卖家 -> 买家）
        // IERC721(listing.nftContract).transferFrom(listing.seller, from, listing.tokenId);
        
        // // 触发NFT售出事件
        // emit NFTSold(listingId, from, listing.seller, listing.nftContract, listing.tokenId, amount);
        
        return true;
    }
    
    // 欠实现bank获取NFT：使用transferWithCallbackAndData购买NFT的辅助函数
    function buyNFTWithCallback(uint256 _listingId) public  {
        // // 检查上架信息是否存在且处于活跃状态
        // Listing storage listing = listings[_listingId];
        // require(listing.isActive, "NFTMarket: listing is not active");
        
        // // 检查买家是否有足够的代币
        // require(paymentToken.balanceOf(msg.sender) >= listing.price, "NFTMarket: insufficient token balance");
        
        // // 编码listingId作为附加数据
        // bytes memory data = abi.encode(_listingId);
        
        // // 调用transferWithCallbackAndData函数，将代币转给市场合约并附带listingId数据
        // bool success = paymentToken.transferWithCallbackAndData(address(this), listing.price, data);
        // require(success, "NFTMarket: token transfer with callback failed");
    }




}




// 上架时Market不获取授权

/*
contract NFTMarket {
    BaseERC20 public token;
    ERC721 public nft;
    
    struct Listing {
        uint256 price;
        address seller;
        bool isActive;
    }
    
    // tokenId => 上架信息
    mapping(uint256 => Listing) public listings;
    
    event Listed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event Unlisted(uint256 indexed tokenId, address indexed seller);
    event Sold(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);

    constructor(address _token, address _nft) {
        token = BaseERC20(_token);
        nft = ERC721(_nft);
    }
    
    // 上架 NFT（不转移 NFT）
    function list(uint256 tokenId, uint256 price) public {
        // 验证调用者是 NFT 所有者
        require(nft.ownerOf(tokenId) == msg.sender, "Not NFT owner");
        
        // 验证 NFT 未被上架
        require(!listings[tokenId].isActive, "Already listed");
        
        // 记录上架信息
        listings[tokenId] = Listing({
            price: price,
            seller: msg.sender,
            isActive: true
        });
        
        emit Listed(tokenId, msg.sender, price);
    }
    
    // 下架 NFT
    function unlist(uint256 tokenId) public {
        Listing storage listing = listings[tokenId];
        require(listing.isActive, "Not listed");
        require(listing.seller == msg.sender, "Not seller");
        
        listing.isActive = false;
        emit Unlisted(tokenId, msg.sender);
    }
    
    // 购买 NFT（核心交易）
    function buyNFT(uint256 tokenId) public {
        Listing storage listing = listings[tokenId];
        require(listing.isActive, "Not for sale");
        
        // 验证当前 NFT 所有者仍是卖家
        require(nft.ownerOf(tokenId) == listing.seller, "Seller no longer owner");
        
        // 验证买家已授权市场操作代币
        require(
            token.allowance(msg.sender, address(this)) >= listing.price,
            "Insufficient allowance"
        );
        
        // 转移代币（买家 → 卖家）
        require(
            token.transferFrom(msg.sender, listing.seller, listing.price),
            "Token transfer failed"
        );
        
        // 转移 NFT（卖家 → 买家）
        // 需要卖家预先授权市场合约
        nft.transferFrom(listing.seller, msg.sender, tokenId);
        
        // 更新状态
        listing.isActive = false;
        emit Sold(tokenId, msg.sender, listing.seller, listing.price);
    }
    
    // 代币接收回调（支持扩展转账）
    function tokensReceived(
        address,
        address from,
        uint256 amount,
        bytes memory data
    ) external {
        require(msg.sender == address(token), "Invalid token");
        
        // 解码数据获取 tokenId
        uint256 tokenId = abi.decode(data, (uint256));
        
        // 验证支付金额匹配
        require(amount == listings[tokenId].price, "Incorrect payment");
        
        // 执行购买
        buyNFT(tokenId);
    }
}
*/
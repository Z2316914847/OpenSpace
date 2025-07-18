// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";

/*
假如这个合约部署，构造函数需要名称、代号、一个图片/视频等等的(他们放在去中性化节点上，这个图片的hash，hash由去中性化节点提供)
*/
contract BaseERC721 {
    using Strings for uint256;
    using Address for address;

    // Token名称
    string private _name;

    // Token代号
    string private _symbol;

    // 固定值，_baseURI 是所有 NFT 共享的基础路径。拼接 tokenId 生成完整的元数据URL（如 https://api.example.com/nfts/1），:_baseURI = "ipfs://QmXyZ/"; tokenURI(1) 返回 "ipfs://QmXyZ/1"
    string private _baseURI;  

    // 所有权映射  记录每个 tokenId 的当前所有者地址
    mapping(uint256 => address) private _owners;  

    // 记录每个地址拥有的 NFT 数量：这段话他想说的是，一个地址可以拥有多个NFT，，我即想有蔡徐坤，又想拥有迪丽热巴，还想拥有邓超
    mapping(address => uint256) private _balances;  

    // 授权管理  记录每个 tokenId 的授权操作者地址
    mapping(uint256 => address) private _tokenApprovals;  

    // 记录全局授权状态（所有者是否授权某操作者管理其所有 NFT）第一层：address owner（NFT 所有者地址）第二层：address operator（被授权操作者地址）.​值​：bool（是否授权）
    mapping(address => mapping(address => bool)) private _operatorApprovals;  

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) {
        /**code*/
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;

    }

    // 实现IERC165，合约必须实现supportsInterface ，参数是 接口address，把address转为bytes4，因为只需要4个字节
    // 检查 interfaceId 是否等于 ERC721 标准接口的标识符。true：表示目标合约实现了 ERC721 接口，false：未实现
    // 钱包/交易所调用 supportsInterface(0x80ac58cd) 确认合约是合法的 ERC721 实现。
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f;   // ERC165 Interface ID for ERC721Metadata
        // 两种方法相等，通过 type() 获取接口的唯一标识符
        // return interfaceId == type(IERC721).interfaceId ||
        //     interfaceId == type(IERC165).interfaceId ||
        //     interfaceId == type(IERC721Metadata);
    }
    
    function name() public view returns (string memory) {
        /**code*/
        return _name;
    }

    function symbol() public view returns (string memory) {
        /**code*/
        return _symbol;
    }

    // 实现IERC721Metadata(这个接口是为了扩展ERC721)的TokenURI函数，MetaData。
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        /**code*/
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");

        // should return baseURI
        string memory baseURI = _baseURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())): "";
    }

    // 铸造一个 NFT
    function mint(address to, uint256 tokenId) public {
        // 判断 tokenId是否存在，存在的话，说明唯一的NFT存在，不能铸造
        // 地址不为空
        require( to!=address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        // 记录 token 所有者
        _owners[tokenId] = to;
    
        // 更新所有者持有的 token 数量
        _balances[to] += 1;
        emit Transfer(address(0), to, tokenId);
    }

    // 查看某个地址的NFT的tokenId集合
    function balanceOf(address owner) public view returns (uint256) {
        /**code*/
        return _balances[owner];
    }
    // 查看某个地址的某个TokenId
    function ownerOf(uint256 tokenId) public view returns (address) {
        /**code*/
        return _owners[tokenId];
    }

    // 某个NFT的所有者，把这个TokenId的NFT授权给to地址，注意to不可以是原本的所有者
    function approve(address to, uint256 tokenId) public {
        /**code*/
        // address owner = ownerOf(tokenId);  // NFT 所有者
        require(to != ownerOf(tokenId), "ERC721: approval to current owner");  // 不能自己给自己
        // 判断两种情况，符合一种即满足NFT转让。第一种是NFT所有者转让NFT，第二种是NFT授权者转让NFT
        require(msg.sender == ownerOf(tokenId) || isApprovedForAll(ownerOf(tokenId), msg.sender), "ERC721: approve caller is not owner nor approved for all");
       _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        /**code*/
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        /**code*/
        // address sender = msg.sender;
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // 查询记录，查询NFT所有者是否授权他人的 
    function isApprovedForAll(
        address owner,
        address operator
    ) public view returns (bool) {
        /**code*/
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        require(_isApprovedOrOwner(msg.sender, tokenId),"ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        /**code*/
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view returns (bool) {
        /**code*/
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        /**code*/
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        require(to != address(0), "ERC721: transfer to the zero address");
        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    // 
    function _approve(address to, uint256 tokenId) internal virtual {
        /**code*/
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason));
                    }
                }
            }
        } else {
            return true;
        }
    }
}

contract BaseERC721Receiver is IERC721Receiver {
    constructor() {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
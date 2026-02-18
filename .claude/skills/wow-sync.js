// wow-sync skill for NamePlateMarkerWheel
// 同步插件代码到魔兽世界目录

const SRC_DIR = "D:\\claude\\NamePlateMarkerWheel\\src";
const DEST_DIR = "F:\\World of Warcraft\\_retail_\\Interface\\AddOns\\NamePlateMarkerWheel";

async function syncToWoW() {
    const fs = require('fs');
    const path = require('path');

    console.log("🎮 正在同步 NamePlateMarkerWheel 到 WoW 插件目录...\n");

    // 检查源目录
    if (!fs.existsSync(SRC_DIR)) {
        console.error(`❌ 源目录不存在: ${SRC_DIR}`);
        return { success: false, error: "Source directory not found" };
    }

    // 创建目标目录（如果不存在）
    if (!fs.existsSync(DEST_DIR)) {
        console.log(`📁 创建目标目录: ${DEST_DIR}`);
        fs.mkdirSync(DEST_DIR, { recursive: true });
    }

    // 获取所有 .lua 和 .toc 文件
    const files = fs.readdirSync(SRC_DIR);
    const filesToSync = files.filter(f => f.endsWith('.lua') || f.endsWith('.toc'));

    if (filesToSync.length === 0) {
        console.log("⚠️ 没有找到需要同步的文件");
        return { success: true, filesCopied: 0 };
    }

    let copied = 0;
    let failed = 0;

    for (const file of filesToSync) {
        const srcPath = path.join(SRC_DIR, file);
        const destPath = path.join(DEST_DIR, file);

        try {
            fs.copyFileSync(srcPath, destPath);
            console.log(`  ✅ ${file}`);
            copied++;
        } catch (err) {
            console.error(`  ❌ ${file}: ${err.message}`);
            failed++;
        }
    }

    console.log(`\n📊 同步完成: ${copied} 个文件成功, ${failed} 个文件失败`);
    console.log(`📂 目标目录: ${DEST_DIR}\n`);

    return {
        success: failed === 0,
        filesCopied: copied,
        filesFailed: failed,
        destination: DEST_DIR
    };
}

// 导出供 Claude Code 调用
module.exports = { syncToWoW };

// 如果直接运行
if (require.main === module) {
    syncToWoW().then(result => {
        process.exit(result.success ? 0 : 1);
    });
}

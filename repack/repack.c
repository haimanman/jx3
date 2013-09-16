// ------------------------------------
// Repack (Clean up JX3 pak files)
//
// Usage: repack.exe
// ------------------------------------
// package.ini check rules:
// ./package.ini; ./bin/zhcn/package.ini
// ------------------------------------
// gcc -Wall -O2 -mno-cygwin repack.c -o /cygdrive/g/game/jx3/repack.exe
// gcc -Wall -O2 -mno-cygwin -DFAKE repack.c -o /cygdrive/g/game/jx3/repack_快速检测.exe
// /bin/i686-pc-mingw32-gcc.exe -Wall -O2 repack.c -o /cygdrive/g/game/jx3/repack.exe
// /bin/i686-pc-mingw32-gcc.exe -Wall -O2 -DFAKE repack.c -o /cygdrive/g/game/jx3/repack_快速检测.exe
//

//#define	FAKE
//#define	HAVE_MMAP

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#ifdef HAVE_MMAP
#include <sys/mman.h>
#endif

// ---------------------------------------------------------------
// CRC32
// ---------------------------------------------------------------
#define CRC32(crc, ch)		(crc = (crc >> 8) ^ crc32tab[(crc ^ (ch)) & 0xff])
static const unsigned int crc32tab[256] = {
	0x00000000, 0x77073096, 0xee0e612c, 0x990951ba,
	0x076dc419, 0x706af48f, 0xe963a535, 0x9e6495a3,
	0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988,
	0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91,
	0x1db71064, 0x6ab020f2, 0xf3b97148, 0x84be41de,
	0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
	0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec,
	0x14015c4f, 0x63066cd9, 0xfa0f3d63, 0x8d080df5,
	0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172,
	0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,
	0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940,
	0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
	0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116,
	0x21b4f4b5, 0x56b3c423, 0xcfba9599, 0xb8bda50f,
	0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924,
	0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d,
	0x76dc4190, 0x01db7106, 0x98d220bc, 0xefd5102a,
	0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
	0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818,
	0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01,
	0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e,
	0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457,
	0x65b0d9c6, 0x12b7e950, 0x8bbeb8ea, 0xfcb9887c,
	0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
	0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2,
	0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb,
	0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0,
	0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9,
	0x5005713c, 0x270241aa, 0xbe0b1010, 0xc90c2086,
	0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
	0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4,
	0x59b33d17, 0x2eb40d81, 0xb7bd5c3b, 0xc0ba6cad,
	0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a,
	0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683,
	0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8,
	0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
	0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe,
	0xf762575d, 0x806567cb, 0x196c3671, 0x6e6b06e7,
	0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc,
	0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5,
	0xd6d6a3e8, 0xa1d1937e, 0x38d8c2c4, 0x4fdff252,
	0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
	0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60,
	0xdf60efc3, 0xa867df55, 0x316e8eef, 0x4669be79,
	0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
	0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f,
	0xc5ba3bbe, 0xb2bd0b28, 0x2bb45a92, 0x5cb36a04,
	0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
	0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a,
	0x9c0906a9, 0xeb0e363f, 0x72076785, 0x05005713,
	0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38,
	0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21,
	0x86d3d2d4, 0xf1d4e242, 0x68ddb3f8, 0x1fda836e,
	0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
	0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c,
	0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45,
	0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2,
	0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db,
	0xaed16a4a, 0xd9d65adc, 0x40df0b66, 0x37d83bf0,
	0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
	0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6,
	0xbad03605, 0xcdd70693, 0x54de5729, 0x23d967bf,
	0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94,
	0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d,
};

static unsigned int crc32(char *s, int len)
{
	int i;
	unsigned int crc = ~0;
	for (i = 0; i < len; i++)
	{
		CRC32(crc, s[i]);
	}
	return ~crc;
}

// ---------------------------------------------------------------
// Unique ID hash table
// ---------------------------------------------------------------
#define	UUID_HASH_SIZE		76799

struct id_node 
{
	unsigned int id;
	struct id_node *next;
};

static struct id_node *id_nodes[UUID_HASH_SIZE];

static void uuid_init()
{
	memset(id_nodes, 0, sizeof(id_nodes));
}

static void uuid_deinit()
{
	struct id_node *node, *p;
	int i = 0;
	while (i < UUID_HASH_SIZE)
	{
		node = id_nodes[i];
		while ((p = node) != NULL)
		{
			node = p->next;
			free(p);
		}
		i++;
	}
}

static int uuid_exists(unsigned int id)
{
	int i = id % UUID_HASH_SIZE;
	struct id_node *node = id_nodes[i];
	while (node != NULL)
	{
		if (node->id == id)
			return 1;
		node = node->next;
	}
	node = (struct id_node *) malloc(sizeof(struct id_node));
	node->id = id;
	node->next = id_nodes[i];
	id_nodes[i] = node;
	return 0;
}

// ---------------------------------------------------------------
// Pak file header
// ---------------------------------------------------------------
#define	XPACK_FILE_SIZE					1900000000	// about 2GB

// frame split size
#define	XPACK_SPLIT_SIZE				2097152
// ucl compress buffer size	(max + max/8 + 256)
#define	XPACK_BUFFER_SIZE				(XPACK_SPLIT_SIZE + (XPACK_SPLIT_SIZE>>3) + 256)

// compress method
#define	XPACK_METHOD_NONE				0x00000000
#define	XPACK_METHOD_FRAGMENT			0x10000000
#define	XPACK_METHOD_COMPRESS			0x20000000

#define	XPACK_COMPRESS_SIZE(x)			((x)->uCompressSizeFlag & 0x07FFFFFF)
#define	XPACK_COMPRESS_FLAG(x)			((x)->uCompressSizeFlag & 0xF0000000)

#define	ECHO(fmt, ...)					printf(fmt, ##__VA_ARGS__); fflush(stdout)
#define	QUIT(fmt, ...)					printf(fmt, ##__VA_ARGS__); puts("Press any key to quit..."); getchar(); exit(0)

struct XPackFileHeader
{
	unsigned char	cSignature[4];		//四个字节的文件的头标志，固定为字符串'PACK'
	unsigned int	uCount;				//数据的条目数
	unsigned int	uIndexTableOffset;	//索引的偏移量
	unsigned int	uDataOffset;		//数据的偏移量
	unsigned int	uCrc32;				//校验和(根据索引表内容数据求得)
	unsigned int	uPakTime;			//打包文件制作时的时间，秒为单位time()
	unsigned char	cReserved[8];		//保留的字节
};

struct XPackIndexInfo
{
	unsigned int	uId;				//子文件id
	unsigned int	uOffset;			//子文件在包中的偏移位置
	unsigned int	uSize;				//子文件的原始大小
	unsigned int	uCompressSizeFlag;	//子文件压缩后的大小和压缩方法
};

struct XPackFileFragmentElemHeader
{
	int				nNumFragment;		//分块的数目
	int				nFragmentInfoOffset;//分块信息表的偏移位置,相对于XPackFileFragmentElemHeader开始位置的偏移
};

struct XPackFileFragmentInfo
{
	unsigned int	uOffset;			//此分块数据的起始处在子文件数据区中的偏移位置,相对于XPackFileFragmentElemHeader开始位置的偏移
	unsigned int	uSize;				//此分块的原始大小
	unsigned int	uCompressSizeFlag;	//此分块压缩后的大小和压缩方法，类似与XPackIndexInfo结构中的uCompressSizeFlag
};

// ---------------------------------------------------------------
// main code
// ---------------------------------------------------------------
// ./package.ini; ./bin/zhcn/package.ini
static const char *game_root[] = { "bin\\zhcn\\", "..\\bin\\zhcn\\", "", NULL };
static char pak_root[128], pak_ini[128];
static int re_index = 0, re_fd = -1;
struct XPackFileHeader re_hdr;
struct XPackIndexInfo *re_info = NULL;
static unsigned int re_info_size = 0;	// 当前 re_info 的容量
static unsigned int re_count = 0;
static unsigned long long re_drop = 0, re_copy = 0;
#ifdef HAVE_MMAP
#ifndef FAKE
static char *re_buf = NULL;
#define	XPACK_MMAP_SIZE		2147483648	// 2GB
#endif
#else
#ifndef FAKE
static char wr_buf[(1<<29)];	// 512 MB
static int wr_off = 0;
#endif
#endif	/* HAVE_MMAP */

struct old_pak
{
	int index;
	char name[64];
	struct old_pak *next;
};

#ifndef HAVE_MMAP
#ifndef FAKE
#define safe_write_flush(fd)	safe_write(fd, NULL, 0)
static int safe_write(int fd, const void *buf, size_t size)
{
	size_t n1, n2 = 0;
	if (buf == NULL)	/* flush */
	{
		buf = wr_buf;
		size = wr_off;
		wr_off = 0;
	}
	else
	{
		if ((size + wr_off) > sizeof(wr_buf))	/* flush */
		{
			if (safe_write_flush(fd) != 1)
				return 0;
		}
		if ((size + wr_off) <= sizeof(wr_buf))
		{
			/* just copy */
			memcpy(wr_buf + wr_off, buf, size);
			wr_off += size;
			return 1;
		}
	}
	while (n2 < size)
	{
		n1 = write(fd, buf + n2, size - n2);
		if (n1 < 0)
		{
			ECHO("写入失败，%s\n", strerror(errno));
			return 0;
		}
		n2 += n1;
	}
	return 1;
}
#endif
#endif

static int safe_copy(int fd, struct XPackIndexInfo *info, char *mbuf)
{
#ifndef FAKE
#ifdef HAVE_MMAP
	memcpy(re_buf, mbuf + info->uOffset, XPACK_COMPRESS_SIZE(info));
#else
	unsigned int n1, n2, n3 = 0;
	char buf[65536];

	n2 = XPACK_COMPRESS_SIZE(info);
	lseek(fd, info->uOffset, SEEK_SET);
	while (n3 < n2)
	{
		n1 = n2 - n3;
		if (n1 > sizeof(buf))
			n1 = sizeof(buf);
		if ((n1 = read(fd, buf, n1)) < 0)
		{
			ECHO("读取失败，%s\n", strerror(errno));
			return 0;
		}
		if (!safe_write(re_fd, buf, n1))
			return 0;
		n3 += n1;
	}
#endif
#endif
	return 1;
}

static int repack_before_add()
{
	if (re_fd < 0)
	{
#ifdef FAKE
		re_fd = 99;
#else
		char fpath[128];
		sprintf(fpath, "%s__tmp_%d.pak", pak_root, re_index);
		if ((re_fd = open(fpath, O_WRONLY | O_TRUNC | O_CREAT | O_BINARY, 0666)) < 0)
		{
			ECHO("无法创建文件：__tmp_%d.pak，%s\n", re_index, strerror(errno));
			return 0;
		}
		lseek(re_fd, sizeof(re_hdr), SEEK_SET);
#ifdef HAVE_MMAP
		if (ftruncate(re_fd, XPACK_MMAP_SIZE) < 0)
		{
			ECHO("无法调整文件大小为 2GB\n");
			close(re_fd);
			unlink(fpath);
			re_fd = -1;
			return 0;
		}
		re_buf = (char *) mmap(NULL, XPACK_MMAP_SIZE, PROT_WRITE, 0, re_fd, 0);
		if (re_buf == NULL)
		{
			ECHO("MMAP 失败\n");
			close(re_fd);
			unlink(fpath);
			return 0;
		}
#endif
#endif
		re_hdr.uIndexTableOffset = sizeof(re_hdr);
		re_hdr.uCount = 0;
		re_index++;
	}
	return 1;
}

static int repack_index_cmp(const void *a, const void *b)
{
	unsigned int idA = ((struct XPackIndexInfo *)a)->uId;
	unsigned int idB = ((struct XPackIndexInfo *)b)->uId;
	if (idA > idB)
		return 1;
	else if (idA < idB)
		return -1;
	else
		return 0;
}

static int repack_after_add(int force)
{
	if (re_fd >= 0)
	{
		if (force == 1 || re_hdr.uIndexTableOffset > XPACK_FILE_SIZE)
		{
			unsigned int re_size = sizeof(struct XPackIndexInfo);
			// sort index
			qsort(re_info, re_hdr.uCount, re_size, repack_index_cmp);
			re_size *= re_hdr.uCount;

			// update header
			time((time_t *) &re_hdr.uPakTime);
			re_hdr.uCrc32 = crc32((char *) re_info, re_size);
#ifndef FAKE
#ifdef HAVE_MMAP
			memcpy(re_buf + re_hdr.uIndexTableOffset, re_info, re_size);
			memcpy(re_buf, &re_hdr, sizeof(re_hdr));
			msync(re_buf, XPACK_MMAP_SIZE, MS_SYNC);
			munmap(re_buf, XPACK_MMAP_SIZE);
			ftruncate(re_fd, re_size + re_hdr.uIndexTableOffset);
#else
			safe_write_flush(re_fd);
			lseek(re_fd, re_hdr.uIndexTableOffset, SEEK_SET);
			if (!safe_write(re_fd, re_info, re_size))
				return 0;
			safe_write_flush(re_fd);
			lseek(re_fd, 0, SEEK_SET);
			write(re_fd, &re_hdr, sizeof(re_hdr));
#endif
			close(re_fd);
#endif
			re_fd = -1;
		}
	}
	return 1;
}

static void repack_file(int fd)
{
	unsigned int copy_size = 0, copy_num = 0, i = 0;
	struct XPackIndexInfo *old_info = NULL, *info, *tmp;
	struct XPackFileHeader *hdr = NULL;
	size_t file_size;
	char *buf = NULL;	// mmap buf

	file_size = (size_t) lseek(fd, 0, SEEK_END);
#ifdef HAVE_MMAP
	// mmap used
	buf = (char*) mmap(NULL, file_size, PROT_READ, 0, fd, 0);
	if (buf == NULL)
	{
		ECHO("失败，MMAP！\n");
		goto re_end;
	}

	// read index info
	hdr = (struct XPackFileHeader *) buf;
	info = old_info = (struct XPackIndexInfo *) (buf + hdr->uIndexTableOffset);
#else
	hdr = (struct XPackFileHeader *) malloc(sizeof(struct XPackFileHeader));
	if (hdr == NULL)
	{
		ECHO("失败，内存不足1！\n");
		goto re_end;
	}
	lseek(fd, 0, SEEK_SET);
	read(fd, hdr, sizeof(struct XPackFileHeader));
	info = old_info = malloc(sizeof(struct XPackIndexInfo) * hdr->uCount);
	if (old_info == NULL)
	{
		ECHO("失败，内存不足11！\n");
		goto re_end;
	}
	lseek(fd, hdr->uIndexTableOffset, SEEK_SET);
	read(fd, old_info, sizeof(struct XPackIndexInfo) * hdr->uCount);
#endif

	// check to extend `re_info`
	if (re_info_size < (re_hdr.uCount + hdr->uCount))
	{	
		re_info_size = re_hdr.uCount + hdr->uCount;
		tmp = (struct XPackIndexInfo *) realloc(re_info, sizeof(struct XPackIndexInfo) * re_info_size);
		if (tmp == NULL)
		{
			re_info_size -= hdr->uCount;
			ECHO("失败，内存不足2！\n");
			goto re_end;
		}
		re_info = tmp;
	}

	// loop for files
	ECHO("文件数：%-6d -> ", hdr->uCount);
	while (i < hdr->uCount)
	{
		if (!repack_before_add())	// 处理 re_fd，检查打开文件
			goto re_end;
		if (!uuid_exists(info->uId))
		{
			tmp = &re_info[re_hdr.uCount++];
			memcpy(tmp, info, sizeof(struct XPackIndexInfo));
			tmp->uOffset = re_hdr.uIndexTableOffset;
			re_hdr.uIndexTableOffset += XPACK_COMPRESS_SIZE(info);
			if (!safe_copy(fd, info, buf))
				goto re_end;
			copy_num++;
			re_count++;
			copy_size += XPACK_COMPRESS_SIZE(info) + sizeof(struct XPackIndexInfo);
			if (!repack_after_add(0))	// 处理 re_fd，检查关闭文件
				goto re_end;
		}
		info++;
		i++;
	}
	ECHO("%-6u，", copy_num);
	re_drop += file_size - copy_size;
	re_copy += copy_size;
	ECHO("垃圾含量：%.1f%%\n", ((double)(file_size - copy_size) / file_size) * 100);

re_end:
#ifdef HAVE_MMAP
	if (buf != NULL)
		munmap(buf, file_size);
	else
#endif
	{
		if (old_info != NULL)
			free(old_info);
		if (hdr != NULL)
			free(hdr);
	}
	close(fd);
}

int main(int argc, char *argv[])
{
	char fpath[128], *ptr;
	const char **root;
	struct old_pak *old_tail = NULL, *old_head = NULL;
	FILE *fp = NULL;
	int fd;

	// find package ini
	for (root = game_root; *root != NULL; root++)
	{
		sprintf(pak_ini, "%spackage.ini", *root);
		if ((fp = fopen(pak_ini, "r")) != NULL)
			break;
	}
	if (fp == NULL)
	{
		QUIT("错误：找不到 'package.ini'，请将程序放在游戏主目录运行\n");
	}
	else
	{
		// load pak files
		while (fgets(fpath, sizeof(fpath) - 1, fp) != NULL)
		{
			ptr = fpath + strlen(fpath);
			while (ptr > fpath && *ptr < ' ')
				*ptr-- = '\0';
			if ((ptr = strchr(fpath, '=')) == NULL)
				continue;
			*ptr++ = '\0';
			if (!strcmp(fpath, "Path"))
				sprintf(pak_root, "%s%s", *root, ptr);
			else
			{
				struct old_pak *op = (struct old_pak *) malloc(sizeof(struct old_pak));
				strcpy(op->name, ptr);	// FIXME: may cause buffer overflow
				op->index = atoi(fpath);
				op->next = NULL;
				if (old_head == NULL)
					old_tail = old_head = op;
				else if (op->index < old_head->index)
				{
					op->next = old_head;
					old_head = op;
				}
				else if (op->index > old_tail->index)
				{
					old_tail->next = op;
					old_tail = op;
				}
				else
				{
					struct old_pak *oop = old_head;
					while (oop->next != NULL)
					{
						if (op->index > oop->index && op->index < oop->next->index)
						{
							op->next = oop->next;
							oop->next = op;
							break;
						}
						oop = oop->next;
					}
				}
			}
		}
		fclose(fp);
	}

	// init hdr
	memset(&re_hdr, 0, sizeof(re_hdr));
	memcpy(re_hdr.cSignature, "PACK", 4);
	re_hdr.uDataOffset = sizeof(re_hdr);

#ifdef FAKE
	ECHO("*** JX3 Pak 冗余检测！(by @海鳗鳗) v1.1 ***\n");
#else
	ECHO("*** JX3 Pak 冗余清理，时间长请耐心！ (by @海鳗鳗) v1.1 ***\n");
#endif

	// init uuid
	uuid_init();
	// process files
	strcpy(fpath, pak_root);
	ptr = fpath + strlen(fpath);
	if (ptr[-1] != '\\' && ptr[-1] != '/')
	{
		*ptr++ = '\\';
		strcat(pak_root, "\\");
	}
	ECHO("检测到 PAK 目录: %s\n检测到 PAK 配置: %s\n", pak_root, pak_ini);
	for (old_tail = old_head; old_tail != NULL; old_tail = old_tail->next)
	{
		ECHO("处理: %-16s ... ", old_tail->name);
		strcpy(ptr, old_tail->name);
		if ((fd = open(fpath, O_RDONLY | O_BINARY)) < 0)
		{
			ECHO("失败，%s\n", strerror(errno));
			continue;
		}
		repack_file(fd);
	}
	repack_after_add(1);

	// check result
	if (re_index < 1)
	{
		QUIT("整理结果似乎失败了！\n");
	}
	ECHO("生成新的 PAK %d 个，包含：%u个文件，新大小：%.2fG，清除垃圾：%.2fG！\n",
		re_index, re_count, (double) re_copy / 1048576000, (double) re_drop / 1048576000);

#ifdef FAKE
	// fake tips
	ECHO("*** 以上检测数据供参考，如需清理请运行 repack.exe ***\n");
#else

	// backcup old package.ini
	strcpy(fpath, pak_ini);
	ptr = fpath + strlen(fpath) - 4;
	strcpy(ptr, "_bak.ini");
	ECHO("备份配置文件到：%s ... ", fpath);
	unlink(fpath);
	if (rename(pak_ini, fpath) < 0)
	{
		QUIT("失败，%s\n", strerror(errno));
	}
	else
	{
		ECHO("OK\n");
	}

	// generate new package.ini
	ECHO("生成新配置文件 ... ");
	if ((fp = fopen(pak_ini, "w")) == NULL)
	{
		rename(fpath, pak_ini);
		ECHO("失败，%s\n", strerror(errno));
	}
	else
	{
		int i;
		char fpath2[128];
		// clean exists: update_re_??.pak
		for (i = 0; i < re_index + re_index; i++)
		{
			sprintf(fpath, "%supdate_re_%d.pak", pak_root, i);
			unlink(fpath);
		}
		fprintf(fp, "[SO3Client]\r\nPath=%s\r\n", pak_root + strlen(*root));
		for (i = 0; re_index > 0; i++)
		{
			re_index--;
			sprintf(fpath, "%supdate_re_%d.pak", pak_root, re_index);
			sprintf(fpath2, "%s__tmp_%d.pak", pak_root, re_index);
			rename(fpath2, fpath);
			fprintf(fp, "%d=update_re_%d.pak\r\n", i, re_index);
		}
		ECHO("OK\n");
	}
#endif

	// deinit uuid
	uuid_deinit();

	// free old paks
	while ((old_tail = old_head) != NULL)
	{
		old_head = old_tail->next;
		free(old_tail);
	}

	// free repack index
	if (re_info != NULL)
		free(re_info);
	QUIT("完成，按<回车>(Enter)关闭程序！\n");
}

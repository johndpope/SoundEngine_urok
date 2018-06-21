#ifndef __ULIB_BASE_DEF_H__
#define __ULIB_BASE_DEF_H__

#if (defined(__WIN32__) || defined(_WIN32)) && !defined(WIN32)
#define WIN32
#endif

#if defined(__ANDROID__) && !defined(ANDROID)
#define ANDROID
#endif

#if defined(__APPLE__)
#include "TargetConditionals.h"
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#define     IPHONE
#define     IOS
#else
#define     MAC
#endif
#endif

#ifdef WIN32
#elif defined(ANDROID) || defined(__APPLE__)
#include <stddef.h>
#include <sys/time.h>

#define WINAPI
#define CALLBACK
#define CALLBACK_NULL (0x00000000l)    /* no callback */
#define NEAR
#define FAR
#define IN
#define OUT
#ifndef __APPLE__
#define FALSE (0)
#define TRUE (1)
#endif
#define __FUNCTION__ (__func__)
#define _stdcall
#define WM_USER (0x400)
#define HWND DWORD
#define MAX_PATH 260

#define stricmp 	strcasecmp
#define ZeroMemory(p,s) memset(p,0,s)
#define Sleep(s) 	usleep((s) * 1000)
#define GetTickCount getTicks
inline int getTicks(void)
{
	int ticks = 0;

	static int first_ticks = 0;
	struct timeval tvp;
	gettimeofday(&tvp, NULL);
	int global_ticks = (int)(tvp.tv_sec * 1000 + tvp.tv_usec / 1000);
	if (first_ticks == 0) {
		first_ticks = global_ticks;
	}
	ticks = global_ticks - first_ticks;

	return ticks;
}

#else
#error "The platform is not defined!"
#endif

#endif /*!__ULIB_BASE_DEF_H__*/

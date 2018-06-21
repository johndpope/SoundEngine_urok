#pragma once

class ISync {
public:
	virtual ~ISync() { }
	virtual void Lock() = 0;
	virtual void UnLock() = 0;
	virtual bool TryLock() = 0;
};

class SafeLock {
public:
	SafeLock(ISync* p) {
		sync_ = p;
		if (sync_ != nullptr) {
			sync_->Lock();
		}
	}
	~SafeLock() {
		if (sync_ != nullptr) {
			sync_->UnLock();
		}
	}
private:
	SafeLock();
	ISync* sync_;
};
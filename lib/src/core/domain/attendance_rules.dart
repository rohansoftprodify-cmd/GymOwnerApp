bool canCheckIn({required bool hasOpenSession}) => !hasOpenSession;

bool canCheckOut({required bool hasOpenSession}) => hasOpenSession;

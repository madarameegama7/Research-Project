import {
  Timestamp,
  arrayUnion,
  collection,
  deleteDoc,
  doc,
  onSnapshot,
  orderBy,
  query,
  updateDoc,
} from 'firebase/firestore';
import { db } from './firebase';

const COMPLAINTS_COLLECTION = 'complaints';

export const COMPLAINT_STATUSES = ['All', 'Pending', 'In Progress', 'Resolved'];

export const subscribeComplaints = (onData, onError) => {
  const complaintsQuery = query(
    collection(db, COMPLAINTS_COLLECTION),
    orderBy('submittedAt', 'desc')
  );

  return onSnapshot(
    complaintsQuery,
    (snapshot) => {
      const complaints = snapshot.docs.map((document) => ({
        id: document.id,
        ...document.data(),
      }));
      onData(complaints);
    },
    onError
  );
};

export const subscribeComplaintById = (complaintId, onData, onError) => {
  return onSnapshot(
    doc(db, COMPLAINTS_COLLECTION, complaintId),
    (snapshot) => {
      if (!snapshot.exists()) {
        onData(null);
        return;
      }

      onData({
        id: snapshot.id,
        ...snapshot.data(),
      });
    },
    onError
  );
};

export const updateComplaintStatus = async (complaintId, status) => {
  await updateDoc(doc(db, COMPLAINTS_COLLECTION, complaintId), {
    status,
    updatedAt: Timestamp.now(),
  });
};

export const addReplyToComplaint = async (complaintId, message, repliedBy = 'Admin') => {
  const replyData = {
    message,
    repliedBy,
    repliedAt: Timestamp.now(),
  };

  await updateDoc(doc(db, COMPLAINTS_COLLECTION, complaintId), {
    replies: arrayUnion(replyData),
    updatedAt: Timestamp.now(),
  });
};

export const deleteComplaint = async (complaintId) => {
  await deleteDoc(doc(db, COMPLAINTS_COLLECTION, complaintId));
};


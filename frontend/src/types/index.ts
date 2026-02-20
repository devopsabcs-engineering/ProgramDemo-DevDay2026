/** Possible program submission statuses. */
export type ProgramStatus =
  | 'DRAFT'
  | 'SUBMITTED'
  | 'UNDER_REVIEW'
  | 'APPROVED'
  | 'REJECTED';

/** Request body for creating a new program submission. */
export interface ProgramRequest {
  programName: string;
  programDescription: string;
  programTypeId: number;
  submittedBy?: string;
  documentUrl?: string;
  /** Requested budget in Canadian dollars (optional). */
  budget?: number | null;
}

/** Response body for a program submission. */
export interface ProgramResponse {
  id: number;
  programName: string;
  programDescription: string;
  programTypeId: number;
  programTypeNameEn: string;
  programTypeNameFr: string;
  status: ProgramStatus;
  submittedBy: string | null;
  reviewedBy: string | null;
  reviewComments: string | null;
  documentUrl: string | null;
  /** Requested budget in Canadian dollars. */
  budget: number | null;
  createdDate: string;
  updatedDate: string;
}

/** Request body for reviewing (approving/rejecting) a program. */
export interface ReviewRequest {
  status: 'APPROVED' | 'REJECTED';
  reviewedBy: string;
  reviewComments?: string;
}

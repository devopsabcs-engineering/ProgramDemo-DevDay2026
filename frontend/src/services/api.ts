import axios from 'axios';
import type { ProgramRequest, ProgramResponse, ReviewRequest } from '../types';

const apiClient = axios.create({
  baseURL: '/api',
  headers: {
    'Content-Type': 'application/json',
  },
});

/**
 * Submits a new program request.
 *
 * @param data - The program submission data
 * @returns The created program response
 */
export async function createProgram(
  data: ProgramRequest
): Promise<ProgramResponse> {
  const response = await apiClient.post<ProgramResponse>('/programs', data);
  return response.data;
}

/**
 * Retrieves a list of programs, optionally filtered by search term.
 *
 * @param search - Optional search string to filter by program name
 * @returns A list of program responses
 */
export async function getPrograms(
  search?: string
): Promise<ProgramResponse[]> {
  const params = search ? { search } : undefined;
  const response = await apiClient.get<ProgramResponse[]>('/programs', {
    params,
  });
  return response.data;
}

/**
 * Retrieves a single program by its ID.
 *
 * @param id - The program ID
 * @returns The program response
 */
export async function getProgramById(id: number): Promise<ProgramResponse> {
  const response = await apiClient.get<ProgramResponse>(`/programs/${id}`);
  return response.data;
}

/**
 * Reviews a program submission by approving or rejecting it.
 *
 * @param id - The program ID to review
 * @param data - The review decision data
 * @returns The updated program response
 */
export async function reviewProgram(
  id: number,
  data: ReviewRequest
): Promise<ProgramResponse> {
  const response = await apiClient.put<ProgramResponse>(
    `/programs/${id}/review`,
    data
  );
  return response.data;
}

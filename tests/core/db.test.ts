import { startDB, stopDB } from '../db';

const execSyncMock = jest.fn();
const connectMock = jest.fn();
const queryMock = jest.fn();
const endMock = jest.fn();

jest.mock('child_process', () => ({ execSync: (...args: any[]) => execSyncMock(...args) }));

jest.mock('pg', () => ({
  Client: jest.fn().mockImplementation(() => ({
    connect: connectMock,
    query: queryMock,
    end: endMock,
  })),
}));

jest.mock('uuid', () => ({ v4: () => '1234' }));

jest.mock('fs', () => ({
  promises: {
    readdir: jest.fn().mockResolvedValue(['001.sql']),
    readFile: jest.fn().mockResolvedValue('CREATE TABLE test (id int);'),
  },
}));

describe('startDB / stopDB', () => {
  test('runs docker commands and applies migrations', async () => {
    const url = await startDB();

    expect(execSyncMock).toHaveBeenCalledWith(
      'docker run -d --rm --name mpb_test_1234 -e POSTGRES_PASSWORD=postgres -p 54329:5432 pgvector/pgvector:pg15',
      { stdio: 'ignore' },
    );
    expect(connectMock).toHaveBeenCalled();
    expect(queryMock).toHaveBeenCalledWith('CREATE TABLE test (id int);');
    expect(url).toBe('postgres://postgres:postgres@localhost:54329/postgres');

    await stopDB();
    expect(execSyncMock).toHaveBeenLastCalledWith('docker stop mpb_test_1234', { stdio: 'ignore' });
  });
});

using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Runtime.InteropServices;

namespace BarixDiscover
{
    class Program
    {
        private const string BroadcastAddress = "255.255.255.255";
        private const int Port = 30718;
        private static readonly TimeSpan Timeout = TimeSpan.FromSeconds(2);
        private static readonly TimeSpan Interval = TimeSpan.FromSeconds(5);
        private static readonly byte[] BarixPrefix = new byte[] { 0x00, 0x08, 0xE1 };
        private static readonly byte[] DiscoveryPayload = new byte[] { 0x81, 0x88, 0x53, 0x81, 0x01 };

        private static readonly string INFO = "#0d6efd";
        private static readonly string SUCCESS = "#28a745";
        private static readonly string ERROR = "#dc3545";
        private static readonly string WARN = "#ffc107";

        private static int warningLine = -1;

        static void Main()
        {
            EnableVirtualTerminal(); // Enable ANSI color support in Windows
            Console.OutputEncoding = Encoding.UTF8;
            var seen = new HashSet<string>();
            bool printedWarning = false;

            WriteColor("Discovering Barix devices (CTRL-C to stop)\n", INFO);
            string header = $"{ "Device IP",-15}  {"MAC Address",-17}";
            WriteColor(header + "\n", INFO);
            WriteColor(new string('-', header.Length) + "\n", INFO);

            Console.CancelKeyPress += (s, e) =>
            {
                WriteColor($"\nDone — found {seen.Count} device(s).\n", SUCCESS);
                Environment.Exit(0);
            };

            try
            {
                while (true)
                {
                    if (printedWarning)
                    {
                        ClearWarning();
                        printedWarning = false;
                    }

                    var replies = DiscoverOnce();
                    bool anyFound = false;

                    foreach (var data in replies)
                    {
                        if (data.Length < 15) continue;

                        var mac = data.Skip(5).Take(6).ToArray();
                        if (!mac.Take(3).SequenceEqual(BarixPrefix)) continue;

                        string macText = BitConverter.ToString(mac).Replace('-', ':');
                        if (seen.Contains(macText)) continue;

                        seen.Add(macText);
                        var ipBytes = data.Skip(11).Take(4).ToArray();
                        string ipText = string.Join(".", ipBytes);

                        WriteColor($"{ipText,-15}  {macText,-17}\n", SUCCESS);
                        anyFound = true;
                    }

                    if (!anyFound)
                    {
                        string ts = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                        string msg = $"{ts} No devices found in this cycle.";
                        PrintWarning(msg, WARN);
                        printedWarning = true;
                    }

                    Thread.Sleep(Interval);
                }
            }
            catch (Exception ex)
            {
                WriteColor($"Error: {ex.Message}\n", ERROR);
                Environment.Exit(1);
            }
        }

        static List<byte[]> DiscoverOnce()
        {
            using (var sendClient = new UdpClient())
            {
                sendClient.EnableBroadcast = true;
                sendClient.Client.Bind(new IPEndPoint(IPAddress.Any, Port));
                sendClient.Send(DiscoveryPayload, DiscoveryPayload.Length,
                    new IPEndPoint(IPAddress.Parse(BroadcastAddress), Port));
            }

            var results = new List<byte[]>();
            using (var recvClient = new UdpClient(Port))
            {
                recvClient.Client.ReceiveTimeout = (int)Timeout.TotalMilliseconds;
                var start = DateTime.UtcNow;
                while (DateTime.UtcNow - start < Timeout)
                {
                    try
                    {
                        IPEndPoint remote = new IPEndPoint(IPAddress.Any, 0);
                        var data = recvClient.Receive(ref remote);
                        results.Add(data);
                    }
                    catch (SocketException ex) when (ex.SocketErrorCode == SocketError.TimedOut)
                    {
                        break;
                    }
                }
            }
            return results;
        }

        static void WriteColor(string text, string hexColor)
        {
            var (r, g, b) = HexToRgb(hexColor);
            Console.Write($"\x1b[38;2;{r};{g};{b}m{text}\x1b[0m");
        }

        static void PrintWarning(string msg, string hexColor)
        {
            warningLine = Console.CursorTop;
            WriteColor(msg + "\n", hexColor);
        }

        static void ClearWarning()
        {
            if (warningLine < 0) return;
            Console.SetCursorPosition(0, warningLine);
            Console.Write("\x1b[2K"); // Clear entire line
            Console.SetCursorPosition(0, warningLine);
            warningLine = -1;
        }

        static (int r, int g, int b) HexToRgb(string hex)
        {
            hex = hex.TrimStart('#');
            return (
                Convert.ToInt32(hex.Substring(0, 2), 16),
                Convert.ToInt32(hex.Substring(2, 2), 16),
                Convert.ToInt32(hex.Substring(4, 2), 16)
            );
        }

        // === ENABLE ANSI COLOR SUPPORT ON WINDOWS ===
        private const int STD_OUTPUT_HANDLE = -11;
        private const uint ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004;

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern IntPtr GetStdHandle(int nStdHandle);

        [DllImport("kernel32.dll")]
        private static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);

        [DllImport("kernel32.dll")]
        private static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);

        static void EnableVirtualTerminal()
        {
            var handle = GetStdHandle(STD_OUTPUT_HANDLE);
            GetConsoleMode(handle, out uint mode);
            mode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
            SetConsoleMode(handle, mode);
        }
    }
}

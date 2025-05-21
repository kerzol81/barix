using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;

namespace BarixDiscover
{
    class Program
    {
        // Configuration
        private const string BroadcastAddress = "255.255.255.255";
        private const int Port = 30718;
        private static readonly TimeSpan Timeout = TimeSpan.FromSeconds(2);
        private static readonly TimeSpan Interval = TimeSpan.FromSeconds(5);
        private static readonly byte[] BarixPrefix = new byte[] { 0x00, 0x08, 0xE1 };
        private static readonly byte[] DiscoveryPayload = new byte[] { 0x81, 0x88, 0x53, 0x81, 0x01 };

        // ANSI‐style colors (Windows 10+ & *nix)
        private static readonly ConsoleColor InfoColor    = ConsoleColor.Blue;
        private static readonly ConsoleColor SuccessColor= ConsoleColor.Green;
        private static readonly ConsoleColor WarnColor   = ConsoleColor.Yellow;
        private static readonly ConsoleColor ErrorColor  = ConsoleColor.Red;
        private static int WarningLine = -1;

        static void Main()
        {
            Console.OutputEncoding = Encoding.UTF8;
            var seen = new HashSet<string>();

            // Print header
            WriteColor("Discovering Barix devices (CTRL-C to stop)\n", InfoColor);
            var header = string.Format("{0,-15}  {1,-17}", "Device IP", "MAC Address");
            WriteColor(header + "\n", InfoColor);
            WriteColor(new string('-', header.Length) + "\n", InfoColor);

            Console.CancelKeyPress += (s, e) =>
            {
                WriteColor($"\nDone — found {seen.Count} device(s).\n", SuccessColor);
            };

            try
            {
                while (true)
                {
                    var replies = DiscoverOnce();
                    bool anyFound = false;

                    // If we previously printed a warning, clear it now
                    if (WarningLine >= 0 && replies.Any())
                    {
                        ClearWarning();
                    }

                    foreach (var data in replies)
                    {
                        if (data.Length < 15) continue;

                        // MAC is bytes 5-10
                        var mac = data.Skip(5).Take(6).ToArray();
                        // filter OUI
                        if (!mac.Take(3).SequenceEqual(BarixPrefix)) continue;
                        var macText = BitConverter.ToString(mac).Replace('-', ':');
                        if (seen.Contains(macText)) continue;

                        seen.Add(macText);
                        // IP is bytes 11-14
                        var ipBytes = data.Skip(11).Take(4).ToArray();
                        var ipText = string.Join(".", ipBytes);

                        WriteColor($"{ipText,-15}  {macText,-17}\n", SuccessColor);
                        anyFound = true;
                    }

                    // If no device this cycle, print one timestamped warning
                    if (!anyFound)
                    {
                        var ts = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                        var msg = $"{ts} No devices found in this cycle.";
                        PrintWarning(msg);
                    }

                    Thread.Sleep(Interval);
                }
            }
            catch (Exception ex)
            {
                WriteColor($"Error: {ex.Message}\n", ErrorColor);
                Environment.Exit(1);
            }
        }

        static List<byte[]> DiscoverOnce()
        {
            // Broadcast the GET packet
            using (var sendClient = new UdpClient())
            {
                sendClient.EnableBroadcast = true;
                sendClient.Client.Bind(new IPEndPoint(IPAddress.Any, Port));
                sendClient.Send(DiscoveryPayload, DiscoveryPayload.Length,
                                new IPEndPoint(IPAddress.Parse(BroadcastAddress), Port));
            }

            // Listen for replies
            var results = new List<byte[]>();
            using (var recvClient = new UdpClient(Port))
            {
                recvClient.Client.ReceiveTimeout = (int)Timeout.TotalMilliseconds;
                var start = DateTime.UtcNow;
                while (DateTime.UtcNow - start < Timeout)
                {
                    try
                    {
                        var remote = new IPEndPoint(IPAddress.Any, 0);
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

        static void WriteColor(string text, ConsoleColor color)
        {
            var prev = Console.ForegroundColor;
            Console.ForegroundColor = color;
            Console.Write(text);
            Console.ForegroundColor = prev;
        }

        static void PrintWarning(string msg)
        {
            // record current cursor line
            WarningLine = Console.CursorTop;
            WriteColor(msg + "\n", WarnColor);
        }

        static void ClearWarning()
        {
            // move cursor to warning line, clear it, then reset cursor below header
            Console.SetCursorPosition(0, WarningLine);
            Console.Write(new string(' ', Console.WindowWidth));
            Console.SetCursorPosition(0, WarningLine);
            WarningLine = -1;
        }
    }
}
